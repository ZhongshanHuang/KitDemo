//
//  PoWeakProxy.swift
//  KitDemo
//
//  Created by iOSer on 2019/7/29.
//  Copyright © 2019 黄中山. All rights reserved.
//

import Foundation

// MARK: - PoWeakProxy

// swift don't support NSProxy
final class PoWeakProxy: NSObject {
    weak var target: AnyObject?
    
    init(target: AnyObject) {
        self.target = target
    }
    
    override func responds(to aSelector: Selector!) -> Bool {
        return target?.responds(to: aSelector) ?? false
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return target
    }
}
