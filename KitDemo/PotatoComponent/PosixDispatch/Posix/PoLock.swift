//
//  PoLock.swift
//  KitDemo
//
//  Created by 黄中山 on 2020/6/9.
//  Copyright © 2020 黄中山. All rights reserved.
//

import Darwin.POSIX.pthread.pthread

class PoLock {
    
    fileprivate let mutex: UnsafeMutablePointer<pthread_mutex_t>
    private let refCount: UnsafeMutablePointer<Int>
    
    init(lock: PoLock? = nil) {
        if let lock = lock {
            mutex = lock.mutex
            refCount = lock.refCount
            refCount.pointee += 1
        } else {
            mutex = .allocate(capacity: 1)
            pthread_mutex_init(mutex, nil)
            refCount = .allocate(capacity: 1)
            refCount.initialize(to: 1)
        }
    }
    
    @inlinable
    func lock() {
        pthread_mutex_lock(mutex)
    }
    
    @inlinable @discardableResult
    func tryLock() -> Bool {
        return pthread_mutex_trylock(mutex) == 0
    }
    
    @inlinable
    func unlock() {
        pthread_mutex_unlock(mutex)
    }
    
    @inlinable @discardableResult
    func lockedPerform<T>(block: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try block()
    }
    
    deinit {
        if refCount.pointee == 1 {
            pthread_mutex_destroy(mutex)
            mutex.deallocate()
            refCount.deallocate()
        } else {
            refCount.pointee -= 1
        }
    }
    
}

//func consume() {
//    while true {
//        condition.lock()
//        condition.wait(while: shared <= 0)
//
//        shared -= 1
//
//        print("-----consume: \(shared)")
//        condition.unlock()
//
//        sleep(1)
//    }
//}
//
//func product() {
//    while true {
//        condition.lock()
//        shared += 1
//        print("product: \(shared)")
//        condition.signal()
//        condition.unlock()
//        sleep(2)
//    }
//}

class PoCondition: PoLock {
    
    private let condition = UnsafeMutablePointer<pthread_cond_t>.allocate(capacity: 1)
    
    override init(lock: PoLock? = nil) {
        pthread_cond_init(condition, nil)
        super.init(lock: lock)
    }
    
    @inlinable
    func wait() {
        pthread_cond_wait(condition, mutex)
    }
    
    @inlinable
    func repeatWait(while cond: @autoclosure () -> Bool) {
        repeat { wait() } while cond()
    }
    
    @inlinable
    func wait(while cond: @autoclosure () -> Bool) {
        while cond() { wait() }
    }
    
    /// 如果没有线程在wait，调用signal的信号会丢失，小心因此造成死锁
    @inlinable
    func signal() {
        pthread_cond_signal(condition)
    }
    
    @inlinable
    func broadcast() {
        pthread_cond_broadcast(condition)
    }
    
    deinit {
        pthread_cond_destroy(condition)
        condition.deallocate()
    }
}
