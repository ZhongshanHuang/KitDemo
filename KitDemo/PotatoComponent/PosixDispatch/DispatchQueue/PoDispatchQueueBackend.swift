//
//  PoDispatchQueueBackend.swift
//  KitDemo
//
//  Created by 黄中山 on 2020/6/10.
//  Copyright © 2020 黄中山. All rights reserved.
//

import Foundation

protocol PoDispatchQueueBackend: class {
    typealias Block = PoThread.Block
    typealias WorkItem<T> = PoDispatchWorkItem<T>
    typealias QoS = PoQosThreadPool.QoS
    
    var qos: QoS { get }
    
    @discardableResult
    func sync<T>(execute work: () throws -> T) rethrows -> T
    
    @discardableResult
    func sync<T>(flags: PoDispatchWorkItemFlags, execute work: () throws -> T) rethrows -> T
    
    func async(group: PoDispatchGroup?, flags: PoDispatchWorkItemFlags, execute work: @escaping Block)
    func async(execute work: @escaping Block)
}

extension PoDispatchQueueBackend {
    
    @discardableResult
    func sync<T>(execute workItem: PoDispatchWorkItem<T>) throws -> T {
        return try sync(flags: workItem.flags) {
            workItem.perform()
            return try workItem.await()
        }
    }
    
    func async<T>(group: PoDispatchGroup? = nil, flags: PoDispatchWorkItemFlags = [], execute work: @escaping () throws -> T) -> PoDispatchWorkItem<T> {
        let item = PoDispatchWorkItem(flags: flags, block: work)
        async(group: group, flags: flags, execute: item.perform)
        return item
    }
    
    func async<T>(group: PoDispatchGroup? = nil, execute: PoDispatchWorkItem<T>) {
        async(group: group, flags: execute.flags, execute: execute.perform)
    }
}
