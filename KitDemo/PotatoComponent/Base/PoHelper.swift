//
//  PoHelper.swift
//  KitDemo
//
//  Created by 黄中山 on 2018/5/27.
//  Copyright © 2018年 黄中山. All rights reserved.
//

import UIKit

/// sys/time version
func PoBenchmark_os(excute: () -> Void, complete: ((Double) -> Void)? = nil) {
    var t0: timeval = timeval()
    var t1: timeval = timeval()
    gettimeofday(&t0, nil)
    excute()
    gettimeofday(&t1, nil)

    let sec = Double(t1.tv_sec - t0.tv_sec) + Double(t1.tv_usec - t0.tv_usec) / 1e6 // 秒，微秒
    if complete == nil {
        print("PoBenchmark_os: \(sec)")
    } else {
        complete?(sec)
    }
}

/// QuartzCore version
func PoBenchmark_qz(excute: () -> Void, complete: ((Double) -> Void)? = nil) {
    let bein = CACurrentMediaTime()
    excute()
    let end = CACurrentMediaTime()
    let sec = end - bein
    if complete == nil {
        print("PoBenchmark_os: \(sec)")
    } else {
        complete?(sec)
    }
}

/// dispatch asynchronously a block on main queue
func Dispatch_async_on_main_queue(block: @escaping () -> Void) {
    if pthread_main_np() != 0 {
        block()
    } else {
        DispatchQueue.main.async(execute: block)
    }
}

/// dispatch synchronously a block on main queue
func Dispatch_sync_on_main_queue(block: @escaping () -> Void) {
    if pthread_main_np() != 0 {
        block()
    } else {
        DispatchQueue.main.sync(execute: block)
    }
}

/// debug log
func PoDebugPrint<T>(_ message: T, file: String = #file, line: Int = #line, method: String = #function) {
    #if DEBUG
    print("\((file as NSString).lastPathComponent)[\(line)], \(method): \(message)")
    #endif
}


