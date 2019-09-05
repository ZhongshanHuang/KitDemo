//
//  DispatchSemaphore+extension.swift
//  KitDemo
//
//  Created by iOSer on 2019/7/29.
//  Copyright © 2019 黄中山. All rights reserved.
//

import Foundation

/// DispatchSemaphore convenience

extension DispatchSemaphore {
    
    func inLock(_ execute: () -> Void) {
        _ = self.wait(timeout: .distantFuture)
        execute()
        self.signal()
    }
    
}
