//
//  Thread+extension.swift
//  KitDemo
//
//  Created by 黄中山 on 2018/5/27.
//  Copyright © 2018年 黄中山. All rights reserved.
//

import Foundation

private let kPoThreadAutoreleasePoolKey = "PoThreadAutoreleasePoolKey"
private let kPoThreadAutoreleasePoolStackKey = "PoThreadAutoreleasePoolStackKey"

extension Thread {
    
    static func addAutoreleasePoolToCurrentRunloop() {
        if pthread_main_np() != 0 { return } // 主线程
        if current.threadDictionary[kPoThreadAutoreleasePoolKey] != nil { return } // 已经添加
        PoRunloopAutoreasePoolSetup()
    }
    
    private static func PoRunloopAutoreasePoolSetup() {
        let runloop = CFRunLoopGetCurrent()
        
        let pushObserver = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault,
                                                              CFRunLoopActivity.entry.rawValue,
                                                              true,
                                                              -0x7FFFFFFF,
                                                              PoAutoreleasePoolRunloopObserverCallBack)
        CFRunLoopAddObserver(runloop, pushObserver, .commonModes)
        
        let popObserver = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault,
                                                             CFRunLoopActivity.beforeWaiting.rawValue | CFRunLoopActivity.exit.rawValue,
                                                             true,
                                                             0x7FFFFFFF,
                                                             PoAutoreleasePoolRunloopObserverCallBack)
        CFRunLoopAddObserver(runloop, popObserver, .commonModes)
    }
    
    private static func PoAutoreleasePoolRunloopObserverCallBack(observer: CFRunLoopObserver?, activity: CFRunLoopActivity) {
        switch activity {
        case CFRunLoopActivity.entry:
            PoAutoreleasePoolPush()
        case CFRunLoopActivity.beforeWaiting:
            PoAutoreleasePoolPop()
            PoAutoreleasePoolPush()
        case CFRunLoopActivity.exit:
            PoAutoreleasePoolPop()
        default:
            break
        }
    }
    
    private static func PoAutoreleasePoolPush() {
        
    }
    
    
    private static func PoAutoreleasePoolPop() {

    }
}


