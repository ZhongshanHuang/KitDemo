//
//  PoThreadPool.swift
//  KitDemo
//
//  Created by 黄中山 on 2020/6/10.
//  Copyright © 2020 黄中山. All rights reserved.
//

import Foundation

class PoThreadPool {
    
    typealias Block = PoThread.Block
    typealias Performer = (@escaping Block) -> Void
    
    let threadNumber: Int
    private let condition = PoCondition()
    private let queue = FifoQueue<Block>()
    private let runLoops: UnsafeMutablePointer<PoRunLoop>
    
    init(threadNumber: Int, perform: Performer? = nil) {
        self.threadNumber = threadNumber
        runLoops = .allocate(capacity: threadNumber)
        let perform = perform ?? { PoThread(block: $0).start() }
        for i in 0..<threadNumber {
            let runLoop = PoRunLoop(condition: condition, iterator: queue.pop)
            (runLoops + i).initialize(to: runLoop)
            perform(runLoop.start)
        }
    }
    
    func subpool(threadNumber: Int) -> PoThreadPool {
        return .init(threadNumber: threadNumber, perform: perform)
    }
    
    func perform(block: @escaping Block) {
        condition.lock()
        queue.push(block)
        condition.signal()
        condition.unlock()
    }
    
    func perform(blocks: [Block]) {
        condition.lock()
        queue.push(blocks)
        condition.broadcast()
        condition.unlock()
    }
    
    deinit {
        (0..<threadNumber).forEach {
            runLoops[$0].cancel()
        }
        runLoops.deinitialize(count: threadNumber)
        runLoops.deallocate()
    }
    
}
