//
//  PoQosThreadPool+QosFifoQueue.swift
//  KitDemo
//
//  Created by 黄中山 on 2020/6/10.
//  Copyright © 2020 黄中山. All rights reserved.
//

import Foundation

extension PoQosThreadPool {
    
    class QosFifoQueue<T> {
        
        private typealias Queue = FifoQueue<T>
        private let queues = UnsafeMutablePointer<Queue>.allocate(capacity: 4)
        
        init() {
            let queues = (0..<4).map { _ in Queue() }
            self.queues.initialize(from: queues, count: 4)
        }
        
        @inlinable
        func push(_ item: T, qos: QoS) {
            queues[qos.rawValue].push(item)
        }
        
        @inlinable
        func push(_ items: [T], qos: QoS) {
            queues[qos.rawValue].push(items)
        }
        
        @inlinable
        func pop(qos: QoS) -> T? {
            return queues[qos.rawValue].pop()
        }
        
        var firstQos: QoS? {
            return (0..<4).first { !queues[$0].isEmpty }.flatMap(QoS.init)
        }
        
        deinit {
            queues.deinitialize(count: 4)
            queues.deallocate()
        }
    }
    
}
