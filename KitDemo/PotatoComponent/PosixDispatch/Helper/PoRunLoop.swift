//
//  PoRunLoop.swift
//  KitDemo
//
//  Created by 黄中山 on 2020/6/9.
//  Copyright © 2020 黄中山. All rights reserved.
//

import Foundation

class PoRunLoop {
    typealias Block = PoThread.Block
    typealias Iterator = () -> Block?
    
    private let iterator: Iterator
    private let condition: PoCondition
    private(set) var isCancelled = false
    
    init(condition: PoCondition, iterator: @escaping Iterator) {
        self.condition = condition
        self.iterator = iterator
    }
    
    func start() {
        condition.lock()
        repeat { loop() } while continueLoop
        condition.unlock()
    }
    
    private var continueLoop: Bool {
        if isCancelled { return false }
        condition.wait()
        return true
    }
    
    private func loop() {
        while let block = iterator() {
            condition.unlock()
            block()
            condition.lock()
        }
    }
    
    func cancel() {
        condition.lock()
        isCancelled = true
        condition.signal()
        condition.unlock()
    }
    
    @inlinable
    func lock() {
        condition.lock()
    }
    
    @inlinable
    func signal() {
        condition.signal()
    }
    
    @inlinable
    func unlock() {
        condition.unlock()
    }
}
