//
//  PoDispatchQueuePool.swift
//  KitDemo
//
//  Created by 黄中山 on 2018/5/24.
//  Copyright © 2018年 黄中山. All rights reserved.
//

import Foundation

private let kMaxQueueCount = 16

class PoDispatchContext {
    let name: String
    let queueCount: Int
    private var queues: [DispatchQueue]
    private lazy var _sentinel: PoSentinel = PoSentinel()
    
    init(name: String, queueCount: Int, qos: DispatchQoS) {
        self.name = name
        self.queueCount = queueCount
        queues = Array<DispatchQueue>()
        queues.reserveCapacity(queueCount)
        for _ in 0..<queueCount {
            queues.append(DispatchQueue(label: name, qos: qos))
        }
    }
    
    func queue() -> DispatchQueue {
        defer { _sentinel.increase() }
        return queues[_sentinel.value() % queueCount]
    }
    
    
    static let backgoundQOS: PoDispatchContext = PoDispatchContext(name: "com.hzs.po.background",
                                                                   queueCount: min(ProcessInfo.processInfo.activeProcessorCount, kMaxQueueCount),
                                                                   qos: .background)
    
    static let utilityQOS: PoDispatchContext = PoDispatchContext(name: "com.hzs.po.utility",
                                                                 queueCount: min(ProcessInfo.processInfo.activeProcessorCount, kMaxQueueCount),
                                                                 qos: .utility)
    
    static let defaultQOS: PoDispatchContext = PoDispatchContext(name: "com.hzs.po.default",
                                                                 queueCount: min(ProcessInfo.processInfo.activeProcessorCount, kMaxQueueCount),
                                                                 qos: .default)
    
    static let userInitiatedQOS: PoDispatchContext = PoDispatchContext(name: "com.hzs.po.userInitiated",
                                                                       queueCount: min(ProcessInfo.processInfo.activeProcessorCount, kMaxQueueCount),
                                                                       qos: .userInitiated)
    
    static let userInteractiveQOS: PoDispatchContext = PoDispatchContext(name: "com.hzs.po.userInteractive",
                                                                         queueCount:min(ProcessInfo.processInfo.activeProcessorCount, kMaxQueueCount),
                                                                         qos: .userInteractive)
    
}


final class PoDispatchQueuePool {
    
    // MARK: - Properties
    let name: String
    private var _context: PoDispatchContext
    
    init(name: String, queueCount: Int, qos: DispatchQoS) {
        if queueCount <= 0 || queueCount > kMaxQueueCount { fatalError("QueueCount is illegal") }
        self._context = PoDispatchContext(name: name, queueCount: queueCount, qos: qos)
        self.name = name
    }
    
    init(context: PoDispatchContext) {
        self._context = context
        name = context.name
    }
    
    func queue() -> DispatchQueue {
        return _context.queue()
    }
    
    static func `default`(_ qos: QualityOfService) -> PoDispatchQueuePool {
        switch qos {
        case .background:
            return backgoundQOS
        case .utility:
            return utilityQOS
        case .default:
            return defaultQOS
        case .userInitiated:
            return userInitiatedQOS
        case .userInteractive:
            return userInteractiveQOS
        default:
            fatalError("The QOS has not implemention.")
        }
    }
    
    static let backgoundQOS: PoDispatchQueuePool = PoDispatchQueuePool(context: PoDispatchContext.backgoundQOS)
    
    static let utilityQOS: PoDispatchQueuePool = PoDispatchQueuePool(context: PoDispatchContext.utilityQOS)
    
    static let defaultQOS: PoDispatchQueuePool = PoDispatchQueuePool(context: PoDispatchContext.defaultQOS)
    
    static let userInitiatedQOS: PoDispatchQueuePool = PoDispatchQueuePool(context: PoDispatchContext.userInitiatedQOS)
    
    static let userInteractiveQOS: PoDispatchQueuePool = PoDispatchQueuePool(context: PoDispatchContext.userInteractiveQOS)
    
}
