//
//  PoSentinel.swift
//  KitDemo
//
//  Created by 黄中山 on 2018/5/24.
//  Copyright © 2018年 黄中山. All rights reserved.
//

import Foundation

//struct PoSentinel {
//
//    // MARK: - Properties
//    private var _value: Int = 0
//    private lazy var _semaphore: DispatchSemaphore = DispatchSemaphore(value: 1)
//
//    // MARK: - Initializers
//    init(value: Int = 0) {
//        self._value = value
//    }
//
//    // MARK: - Methods
//    @discardableResult
//    mutating func value() -> Int {
//        _ = _semaphore.wait(timeout: .distantFuture)
//        defer { _semaphore.signal() }
//        return _value
//    }
//
//    @discardableResult
//    mutating func increase() -> Int {
//        _ = _semaphore.wait(timeout: .distantFuture)
//        defer { _semaphore.signal() }
//        _value += 1
//        if _value == Int.max { _value = 0 } // 防止增长到2^(w-1) + 1后越界，swift会造成数据溢出而报错；c会变成最大的负数。
//        return _value
//    }
//}


//class PoSentinel {
//
//    // MARK: - Properties
//    private var _value: Int = 0
//    private var _valuePtr: UnsafeMutablePointer<Int> {
//        return _getUnsafePointerToStoredProperties(self).assumingMemoryBound(to: Int.self)
//    }
//
//    // MARK: - Initializers
//    init(value: Int = 0) {
//        self._value = value
//    }
//
//    // MARK: - Methods
//    @discardableResult
//    func value() -> Int {
//        _swift_stdlib_atomicLoadInt(object: _valuePtr)
//    }
//
//    @discardableResult
//    func increase() -> Int {
//        _swift_stdlib_atomicFetchAddInt(object: _valuePtr, operand: 1)
//    }
//}

struct PoSentinel {
    
    // MARK: - Properties
    private var _value: Int = 0
    
    private mutating func _valuePtr() -> UnsafeMutablePointer<Int> {
        withUnsafeMutablePointer(to: &_value) { (ptr) -> UnsafeMutablePointer<Int> in
            return ptr
        }
    }
    
    // MARK: - Initializers
    init(value: Int = 0) {
        self._value = value
    }
    
    // MARK: - Methods
    @discardableResult
    mutating func value() -> Int {
        _swift_stdlib_atomicLoadInt(object: _valuePtr())
    }
    
    @discardableResult
    mutating func increase() -> Int {
        _swift_stdlib_atomicFetchAddInt(object: _valuePtr(), operand: 1)
    }
}
