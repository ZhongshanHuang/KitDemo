//
//  PoConditionStorage.swift
//  KitDemo
//
//  Created by 黄中山 on 2020/6/10.
//  Copyright © 2020 黄中山. All rights reserved.
//

import Foundation

class PoConditionStorage {
    
    private let lock: PoLock
    private var conditions = [Int: PoCondition]()
    private var pool = ContiguousArray<PoCondition>()
    
    init(lock: PoLock) {
        self.lock = lock
    }
    
    @inlinable
    func signal(index: Int, count: Int = 1) {
        guard let condition = removeCondition(index: index) else { return }
        (0..<count).forEach { _ in condition.signal() }
    }
    
    @inlinable
    func broadcast(index: Int) {
        removeCondition(index: index)?.broadcast()
    }
    
    @inlinable
    func wait(index: Int) {
        condition(for: index).wait()
    }
    
    @inlinable
    func wait(index: Int, while closure: @escaping () -> Bool) {
        let condition = self.condition(for: index)
        while closure() {
            condition.wait()
        }
    }
    
    @inlinable
    func repeatWait(index: Int, while closure: @escaping () -> Bool) {
        let condition = self.condition(for: index)
        repeat {
            condition.wait()
        } while closure()
    }
    
    private func removeCondition(index: Int) -> PoCondition? {
        guard let condition = conditions.removeValue(forKey: index) else { return nil }
        pool.append(condition)
        return condition
    }
    
    private func condition(for index: Int) -> PoCondition {
        if let condition = conditions[index] { return condition }
        let condition = pool.popLast() ?? PoCondition(lock: lock)
        conditions[index] = condition
        return condition
    }
}
