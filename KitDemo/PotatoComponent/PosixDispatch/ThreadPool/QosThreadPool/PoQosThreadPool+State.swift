//
//  PoQosThreadPool+State.swift
//  KitDemo
//
//  Created by 黄中山 on 2020/6/10.
//  Copyright © 2020 黄中山. All rights reserved.
//

import Foundation

extension PoQosThreadPool {
    
    class State {
        let threadNumber: Int
        let queue = QosFifoQueue<Block>()
        private let performing = UnsafeMutablePointer<Int>.allocate(capacity: 4)
        private let maxThreads: UnsafePointer<Int>
        private var freeThreads: Int
        
        init(threadNumber: Int) {
            self.threadNumber = threadNumber
            freeThreads = threadNumber
            performing.assign(repeating: 0, count: 4)
            let max = QoS.allCases.map { Int($0.maxThreads * Float(threadNumber)) }
            let maxThreads = UnsafeMutablePointer<Int>.allocate(capacity: 4)
            maxThreads.initialize(from: max, count: 4)
            self.maxThreads = .init(maxThreads)
        }
        
        func canPerform(qos: QoS) -> Bool {
            if freeThreads == 0 { return false }
            let max = maxThreads[qos.rawValue]
            var sum = 0
            for i in (0..<qos.rawValue).reversed() {
                sum += performing[i]
                if sum >= max { return false }
            }
            return true
        }
        
        @inlinable
        func startperforming(qos: QoS) {
            freeThreads -= 1
            performing[qos.rawValue] += 1
        }
        
        @inlinable
        func endPerforming(qos: QoS) {
            freeThreads += 1
            performing[qos.rawValue] -= 1
        }
        
        deinit {
            performing.deallocate()
            maxThreads.deallocate()
        }
        
    }
    
}
