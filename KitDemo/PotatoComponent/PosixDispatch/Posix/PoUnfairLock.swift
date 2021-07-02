//
//  PoUnfairLock.swift
//  KitDemo
//
//  Created by 黄中山 on 2020/6/15.
//  Copyright © 2020 黄中山. All rights reserved.
//

import Foundation
/*
* This lock must be unlocked from the same thread that locked it, attempts to
* unlock from a different thread will cause an assertion aborting the process.
*/
class PoUnfairLock {
    
    private let unfairLock: os_unfair_lock_t
    
    init() {
        unfairLock = UnsafeMutablePointer<os_unfair_lock_s>.allocate(capacity: 1)
        unfairLock.initialize(to: os_unfair_lock_s())
    }
    
    @inlinable
    func lock() {
        os_unfair_lock_lock(unfairLock)
    }
    
    @inlinable
    func unlock() {
        os_unfair_lock_unlock(unfairLock)
    }
    
    @inlinable
    func tryLock() -> Bool {
        os_unfair_lock_trylock(unfairLock)
    }
    
    deinit {
        unfairLock.deinitialize(count: 1)
        unfairLock.deallocate()
    }
    
}
