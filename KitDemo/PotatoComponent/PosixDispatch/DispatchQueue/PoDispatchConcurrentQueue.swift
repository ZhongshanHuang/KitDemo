//
//  PoDispatchConcurrentQueue.swift
//  KitDemo
//
//  Created by 黄中山 on 2020/6/11.
//  Copyright © 2020 黄中山. All rights reserved.
//

import Foundation

extension PoDispatchConcurrentQueue {
    
    private struct Item {
        let index: Int
        var sync: Int
        var async: Int
        var barrier: Bool
        var count: Int {
            return async + sync
        }
        var isEmpty: Bool {
            return async == 0 && sync == 0
        }
        
        init(sync: Int = 0, async: Int = 0, index: Int, barrier: Bool = false) {
            self.sync = sync
            self.async = async
            self.index = index
            self.barrier = barrier
        }
        
    }
    
}


class PoDispatchConcurrentQueue: PoDispatchQueueBackend {
    
    private let lock = PoLock()
    let qos: QoS
    
    init(threadPool: PoQosThreadPool, qos: QoS) {
        self.threadPool = threadPool
        self.qos = qos
    }
    
    // MARK: - Threads
    private let threadPool: PoQosThreadPool
    
    private func performAsync() {
        threadPool.perform(qos: qos) {
            self.asyncBlock()
        }
    }
    
    private func asyncBlock() {
        lock.lock()
        defer { lock.unlock() }
        
        while currentItem.async != 0, let block = blockQueue.pop() {
            currentItem.async -= 1
            perform(block: block)
        }
    }
    
    // MARK: - Items
    
    private let itemQueue = FifoQueue<Item>()
    private var currentItem = Item(index: 0)
    private var lastItem = Item(index: 1)
    private var indexCounter = 2
    
    private var nextIndex: Int {
        defer { indexCounter += 1 }
        return indexCounter
    }
    
    private func resumeNextItem() {
        if let item = itemQueue.pop() {
            currentItem = item
        } else if lastItem.isEmpty {
            currentItem.barrier = false
            performing = 0
            return
        } else {
            currentItem = lastItem
            lastItem = .init(index: nextIndex)
        }
        performing = currentItem.count
        signalConditions()
    }
    
    private func signalConditions() {
        if currentItem.sync != 0 {
            syncConditions.broadcast(index: currentItem.index)
        }
        for _ in 0..<min(currentItem.async, threadPool.threadNumber) {
            performAsync()
        }
    }
    
    private func pushBarrier(item: Item) {
        if lastItem.count != 0 {
            itemQueue.push(lastItem)
        }
        itemQueue.push(item)
        lastItem = .init(index: nextIndex)
    }
    
        // MARK: - Performing block
    
    private var performing = 0
    
    private func perform<T>(block: () throws -> T) rethrows -> T {
        lock.unlock()
        defer { didFinishPerforming() }
        return try block()
    }
    
    private func didFinishPerforming() {
        lock.lock()
        performing == 1 ? resumeNextItem() : (performing -= 1)
    }
    
    // MARK: - Async
    
    private let blockQueue = FifoQueue<Block>()
    
    func async(execute work: @escaping Block) {
        lock.lock()
        blockQueue.push(work)
        addNotBarrierAsyncCount()
        lock.unlock()
    }
    
    func async(group: PoDispatchGroup? = nil, flags: PoDispatchWorkItemFlags = [], execute work: @escaping Block) {
        lock.lock()
        blockQueue.push(group.block(with: work))
        flags.contains(.barrier)
            ? addBarrierAsyncCount()
            : addNotBarrierAsyncCount()
        lock.unlock()
    }
    
    private func addNotBarrierAsyncCount() {
        guard !currentItem.barrier, itemQueue.isEmpty else {
            lastItem.async += 1
            return
        }
        currentItem.async += 1
        performing += 1
        performAsync()
    }
    
    private func addBarrierAsyncCount() {
        guard performing == 0 else {
            pushBarrier(item: .init(async: 1, index: nextIndex, barrier: true))
            return
        }
        currentItem = .init(async: 1, index: nextIndex, barrier: true)
        performing = 1
        performAsync()
    }
    
    // MARK: - Sync
    
    private lazy var syncConditions = PoConditionStorage(lock: lock)
    
    @discardableResult func sync<T>(execute work: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        
        waitForNotBarrier()
        return try perform(block: work)
    }
    
    @discardableResult
    func sync<T>(flags: PoDispatchWorkItemFlags, execute work: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        
        flags.contains(.barrier) ? waitForBarrier() : waitForNotBarrier()
        return try perform(block: work)
    }
    
    private func waitForBarrier() {
        if performing == 0 {
            currentItem.barrier = true
            performing = 1
        } else {
            let index = nextIndex
            pushBarrier(item: .init(sync: 1, index: index, barrier: true))
            syncConditions.wait(index: index)
            currentItem.sync -= 1
        }
    }
    
    private func waitForNotBarrier() {
        guard currentItem.barrier || !itemQueue.isEmpty else {
            performing += 1
            return
        }
        
        lastItem.sync += 1
        syncConditions.wait(index: lastItem.index)
        currentItem.sync -= 1
    }
    
}
