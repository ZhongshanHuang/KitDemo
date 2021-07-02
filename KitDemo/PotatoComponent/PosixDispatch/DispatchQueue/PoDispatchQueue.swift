//
//  PoDispatchQueue.swift
//  KitDemo
//
//  Created by 黄中山 on 2020/6/10.
//  Copyright © 2020 黄中山. All rights reserved.
//

import Foundation

extension PoDispatchQueue {
    
    struct Attributes: OptionSet {
        static let concurrent = Attributes(rawValue: 1 << 0)
        let rawValue: Int
    }
    
}

class PoDispatchQueue: PoDispatchQueueBackend {

    let label: String
    private let backend: PoDispatchQueueBackend
    var qos: QoS {
        return backend.qos
    }
    
    init(label: String = "", qos: QoS = .utility, attributes: Attributes = []) {
        self.label = label
        backend = attributes.contains(.concurrent) ? PoDispatchConcurrentQueue(threadPool: .global, qos: qos) : PoDispatchSerialQueue()
    }
    
    // MARK: - PoDispatchQueueBackend
    
    @inlinable @discardableResult
    func sync<T>(execute work: () throws -> T) rethrows -> T {
        return try backend.sync(execute: work)
    }
    
    @inlinable @discardableResult
    func sync<T>(flags: PoDispatchWorkItemFlags, execute work: () throws -> T) rethrows -> T {
        return try backend.sync(flags: flags, execute: work)
    }
    
    @inlinable
    func async(execute work: @escaping Block) {
        backend.async(execute: work)
    }
    
    @inlinable
    func async(group: PoDispatchGroup? = nil, flags: PoDispatchWorkItemFlags = [], execute work: @escaping Block) {
        backend.async(group: group, flags: flags, execute: work)
    }
    
    // MARK: - Global queues
    
    private static let queues = QoS.allCases
        .map { PoDispatchQueue(label: "com.global\($0.rawValue)", qos: $0, attributes: .concurrent) }
    
    static func global(qos: QoS = .utility) -> PoDispatchQueue {
        return queues[qos.rawValue]
    }
    
    // MARK: - Concurrent Perform
    
    static func concurrentPerform(iterations: Int, execute work: @escaping (Int) -> Void) {
        let group = PoDispatchGroup(count: iterations)
        PoThreadPool(threadNumber: Sysconf.processorsCount)
            .perform(blocks: (0..<iterations).map { i in { work(i); group.leave() } })
        group.wait()
    }
}
