//
//  PoDispatchSemaphore.swift
//  KitDemo
//
//  Created by 黄中山 on 2020/6/9.
//  Copyright © 2020 黄中山. All rights reserved.
//

import Foundation

class PoDispatchSemaphore {
    
    private let condition = PoCondition()
    private var value: Int
    
    init(value: Int = 0) {
        self.value = value
    }
    
    @inlinable
    func wait() {
        condition.lock()
        value -= 1
        if value < 0 { condition.wait() }
        condition.unlock()
    }
    
    @inlinable @discardableResult
    func signal() -> Bool {
        condition.lock()
        defer { condition.unlock() }
        if value < 0 {
            value += 1
            condition.signal()
            return true
        } else {
            value += 1
            return false
        }
    }
    
}
