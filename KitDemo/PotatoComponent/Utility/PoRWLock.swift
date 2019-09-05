//
//  PoRWLock.swift
//  KitDemo
//
//  Created by 黄山哥 on 2019/3/18.
//  Copyright © 2019 黄中山. All rights reserved.
//

import Foundation

class PoRWLock {
    private lazy var lock = pthread_rwlock_t()
    
    func rdLock() {
        pthread_rwlock_rdlock(&lock)
    }
    
    func tryRDLock() -> Bool {
        return pthread_rwlock_tryrdlock(&lock) == 0
    }
    
    func rdUnlock() {
        pthread_rwlock_unlock(&lock)
    }
    
    func tryWRLock() -> Bool {
        return pthread_rwlock_trywrlock(&lock) == 0
    }
    
    func wrLock() {
        pthread_rwlock_wrlock(&lock)
    }
    
    func wrUnlock() {
        pthread_rwlock_unlock(&lock)
    }
    
    deinit {
        pthread_rwlock_destroy(&lock)
    }
}
