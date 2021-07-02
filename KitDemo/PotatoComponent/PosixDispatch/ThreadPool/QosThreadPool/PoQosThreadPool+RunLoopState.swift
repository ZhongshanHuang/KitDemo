//
//  PoQosThreadPool+RunLoopState.swift
//  KitDemo
//
//  Created by 黄中山 on 2020/6/10.
//  Copyright © 2020 黄中山. All rights reserved.
//

import Foundation

extension PoQosThreadPool {
    
    class RunLoopState {
        
        private let poolState: State
        private var isRunning = false
        private var lastQos = QoS.utility
        
        init(poolState: State) {
            self.poolState = poolState
        }
        
        func next() -> Block? {
            guard let qos = poolState.queue.firstQos else {
                cancelPerform()
                return nil
            }
            
            return performNext(qos: qos) ? poolState.queue.pop(qos: qos) : nil
        }
        
        private func performNext(qos: QoS) -> Bool {
            if qos == lastQos {
                startPerform(qos: qos)
                return true
            }
            cancelPerform()
            if !poolState.canPerform(qos: qos) { return false }
            startPerform(qos: qos)
            lastQos = qos
            return true
        }
        
        private func startPerform(qos: QoS) {
            if isRunning { return }
            poolState.startperforming(qos: qos)
            isRunning = true
        }
        
        private func cancelPerform() {
            guard isRunning else { return }
            poolState.endPerforming(qos: lastQos)
            isRunning = false
        }
    }
    
}
