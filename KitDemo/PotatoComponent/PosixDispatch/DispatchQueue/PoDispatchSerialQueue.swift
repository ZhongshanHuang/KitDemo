//
//  PoDispatchSerialQueue.swift
//  KitDemo
//
//  Created by 黄中山 on 2020/6/10.
//  Copyright © 2020 黄中山. All rights reserved.
//

import Foundation

extension PoDispatchSerialQueue {
    
    private class Blocks {
        var blocks: ContiguousArray<Block>
        init(_ block: @escaping Block) {
            blocks = [block]
        }
    }
    
    private enum Item {
        case sync(Int)
        case async(Blocks)
    }
    
}

class PoDispatchSerialQueue: PoDispatchQueueBackend {
    
    private let lock = PoLock()
    private var performing = false
    var qos: QoS {
        return .utility
    }
    
    init() {
        PoThread(block: runLoop.start).start()
    }
    
    // MARK: - Queue
    
    private let queue = FifoQueue<Item>()
    
    private func startNextItem() {
        switch queue.first {
        case .sync(let index):
            syncConditions.signal(index: index)
        case .async:
            runLoop.signal()
        default:
            performing = false
        }
    }
    
    // MARK: - RunLoop
    
    private lazy var runLoop: PoRunLoop = {
        let queue = self.queue
        return PoRunLoop(condition: PoCondition(lock: lock)) { [weak self] in
            switch queue.first {
            case .async(let blocks):
                queue.pop()
                return { blocks.blocks.forEach({ $0() }) }
            case .sync(let index):
                self?.syncConditions.signal(index: index)
            default:
                self?.performing = false
            }
            return nil
        }
    }()
    
    // MARK: - Async
    
    func async(execute work: @escaping Block) {
        lock.lock()
        defer { lock.unlock() }
        
        if case .async(let blocks) = queue.last {
            blocks.blocks.append(work)
        } else {
            queue.push(.async(.init(work)))
            startAsyncPerforming()
        }
    }
    
    func async(group: PoDispatchGroup? = nil, flags: PoDispatchWorkItemFlags = [], execute work: @escaping Block) {
        let block = group.block(with: work)
        guard flags.contains(.enforceQoS) else { return async(execute: block) }
        lock.lock()
        queue.insertInStart(.async(.init(block)))
        startAsyncPerforming()
        lock.unlock()
    }
    
    private func startAsyncPerforming() {
        if performing { return }
        performing = true
        runLoop.signal()
    }
    
    // MARK: - Sync
    
    private lazy var syncConditions = PoConditionStorage(lock: lock)
    private var syncIndex = 0
    
    @discardableResult
    func sync<T>(execute work: () throws -> T) rethrows -> T {
        lock.lockedPerform { waitSync(enforce: false) }
        defer { lock.lockedPerform(block: startNextItem) }
        return try work()
    }
    
    @discardableResult
    func sync<T>(flags: PoDispatchWorkItemFlags, execute work: () throws -> T) rethrows -> T {
        lock.lockedPerform { waitSync(enforce: flags.contains(.enforceQoS)) }
        defer { lock.lockedPerform(block: startNextItem) }
        return try work()
    }
    
    private func waitSync(enforce: Bool) {
        defer { performing = true }
        guard performing else { return }
        let index = syncIndex
        syncIndex += 1
        enforce ? queue.insertInStart(.sync(index)) : queue.push(.sync(index))
        syncConditions.wait(index: index)
        queue.pop()
    }
    
    deinit {
        runLoop.cancel()
    }
}
