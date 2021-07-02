//
//  PoQosThreadPool.swift
//  KitDemo
//
//  Created by 黄中山 on 2020/6/10.
//  Copyright © 2020 黄中山. All rights reserved.
//

import Foundation

class PoQosThreadPool {
    
    typealias Block = PoThread.Block
    typealias Performer = (@escaping Block) -> Void
    
    static let global = PoQosThreadPool(threadNumber: 64)
    
    private let condition = PoCondition()
    private let state: State
    private let runLoops: UnsafeMutablePointer<PoRunLoop>
    var threadNumber: Int {
        return state.threadNumber
    }
    
    init(threadNumber: Int, perform: Performer? = nil) {
        state = State(threadNumber: threadNumber)
        runLoops = .allocate(capacity: threadNumber)
        let perform = perform ?? { PoThread(block: $0).start() }
        for i in 0..<threadNumber {
            let runLoop = newRunLoop()
            (runLoops + i).initialize(to: runLoop)
            perform(runLoop.start)
        }
    }
    
    private func newRunLoop() -> PoRunLoop {
        let loopState = RunLoopState(poolState: state)
        return PoRunLoop(condition: condition, iterator: { loopState.next() })
    }
    
    func perform(qos: QoS = .utility, block: @escaping Block) {
        condition.lock()
        state.queue.push(block, qos: qos)
        if state.canPerform(qos: qos) {
            condition.signal()
        }
        condition.unlock()
    }
    
    func perform(qos: QoS = .utility, blocks: [Block]) {
        condition.lock()
        state.queue.push(blocks, qos: qos)
        if state.canPerform(qos: qos) {
            condition.broadcast()
        }
        condition.unlock()
    }
    
    /// 子线程池使用的父线程池的线程，没有新建，暂时想不出来这个的场景
    func subpool(threadNumber: Int, qos: QoS = .utility) -> PoThreadPool {
        return .init(threadNumber: threadNumber, perform: { self.perform(qos: qos, block: $0) })
    }
    
    deinit {
        (0..<threadNumber).forEach {
            runLoops[$0].cancel()
        }
        runLoops.deinitialize(count: threadNumber)
        runLoops.deallocate()
        condition.broadcast()
    }
}
