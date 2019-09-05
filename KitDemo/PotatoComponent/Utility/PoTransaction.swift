//
//  PoTransaction.swift
//  KitDemo
//
//  Created by 黄中山 on 2018/5/23.
//  Copyright © 2018年 黄中山. All rights reserved.
//

import Foundation

extension PoTransaction {
    
    private struct Transaction: Hashable {
        var target: AnyObject
        var selector: Selector
        
        static func == (lhs: Transaction, rhs: Transaction) -> Bool {
            return lhs.target === rhs.target && lhs.selector == rhs.selector
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(target.hash)
            hasher.combine(selector)
        }
    }
    
}


final class PoTransaction {
    private static var _transactionSet: Set<Transaction> = []
    private static var _onceToken: Bool = false
    
    private init() {}

    // MARK: - Methods - [public]
    static func commit(with target: AnyObject, selector: Selector) {
        let transaction = Transaction(target: target, selector: selector)
        _transactionSet.insert(transaction)
        _commit()
    }
    
    private static func _commit() {
        if _onceToken == false {
            let runloop = CFRunLoopGetMain()
            let observer = CFRunLoopObserverCreateWithHandler(
                kCFAllocatorDefault, // 默认的内存分配器
                CFRunLoopActivity.beforeWaiting.rawValue | CFRunLoopActivity.exit.rawValue, // runloop的活动阶段
                true, // 是否多次调用
            0xFFFFFF) { (observer, activity) in
                
                if _transactionSet.isEmpty {
                    return
                }
                let currentSet = _transactionSet
                _transactionSet.removeAll()
                for transaction in currentSet {
                    _ = transaction.target.perform(transaction.selector)
                }
            }
            
            CFRunLoopAddObserver(runloop, observer, CFRunLoopMode.commonModes)
            _onceToken = true
        }
    }
}

