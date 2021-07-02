//
//  PoDispatchGroup.swift
//  KitDemo
//
//  Created by 黄中山 on 2020/6/9.
//  Copyright © 2020 黄中山. All rights reserved.
//

import UIKit

class PoDispatchGroup {
    
    private var count: Int
    private let condition = PoCondition()
    
    init(count: Int = 0) {
        self.count = count
    }
    
    @inlinable
    func enter() {
        condition.lockedPerform(block: { count += 1 })
    }
    
    @inlinable
    func leave() {
        condition.lock()
        count -= 1
        if count == 0 { condition.signal() }
        condition.unlock()
    }
    
    @inlinable
    func wait() {
        condition.lock()
        if count != 0 { condition.wait() }
        condition.unlock()
    }
    
    @inlinable
    func notify(qos: DispatchQoS = .unspecified, flags: DispatchWorkItemFlags = [], queue: DispatchQueue, execute work: @escaping @convention(block) () -> Void) {
        if qos != .unspecified || !flags.isEmpty {
            let item = DispatchWorkItem(qos: qos, flags: flags) {
                self.condition.lock()
                if self.count != 0 { self.condition.wait() }
                work()
                self.condition.unlock()
            }
            queue.async(execute: item)
        } else {
            queue.async {
                self.condition.lock()
                if self.count != 0 { self.condition.wait() }
                work()
                self.condition.unlock()
            }
        }
    }
}

extension Optional where Wrapped: PoDispatchGroup {
    
    func block(with work: @escaping PoThread.Block) -> PoThread.Block {
        guard let group = self else { return work }
        group.enter()
        return { work(); group.leave() }
    }
    
}
