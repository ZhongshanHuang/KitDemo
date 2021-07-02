//
//  PoThread.swift
//  KitDemo
//
//  Created by 黄中山 on 2020/6/8.
//  Copyright © 2020 黄中山. All rights reserved.
//

import Darwin.POSIX.unistd

class PoThread {
    
    @inlinable
    static var current: PoThread {
        return PoThread(with: pthread_self())
    }
    
    @inlinable
    static var isMainThread: Bool {
        return pthread_main_np() != 0
    }
    
    /// 放弃本次分到的时间片
    @inlinable
    static func yield() {
        pthread_yield_np()
    }
    
    typealias Block = () -> Void
    private lazy var block = UnsafeMutablePointer<Block?>.allocate(capacity: 1)
    private let thread = UnsafeMutablePointer<pthread_t?>.allocate(capacity: 1)
    private var started = false
    
    init(block: @escaping Block) {
        self.block.initialize(to: block)
    }
    
    private init(with thread: pthread_t) {
        self.thread.initialize(to: thread)
    }
    
    func start() {
        if started { return }
        started = true
        pthread_create(thread, nil, {
            let pointer = $0.assumingMemoryBound(to: PoThread.Block?.self)
            if let block = pointer.pointee {
                block()
                pointer.deinitialize(count: 1)
            }
            pointer.deallocate()
            return nil
        }, block)
    }
    
    @inlinable
    func wait() {
        guard let thread = thread.pointee else { return }
        pthread_join(thread, nil)
    }
    
    @inlinable
    var priority: Float {
        get { return thread.pointee?.priority ?? 0.5 }
        set { thread.pointee?.priority = newValue }
    }
    
    deinit {
        thread.deallocate()
        if !started { block.deallocate() }
    }
    
}

extension PoThread: Equatable {
    
    static func == (lhs: PoThread, rhs: PoThread) -> Bool {
        return pthread_equal(lhs.thread.pointee, rhs.thread.pointee) != 0
    }
    
}

extension pthread_t {
    
    fileprivate var priority: Float {
        get {
            let params = getSchedParams()
            let range = priorityRange(for: params.policy)
            let length = range.upperBound - range.lowerBound
            if length == 0 { return 0.5 }
            let priority = Float(params.param.sched_priority)
            return (priority - range.lowerBound) / length
        }
        set {
            var params = getSchedParams()
            let range = priorityRange(for: params.policy)
            let priority = (range.upperBound - range.lowerBound) * newValue + range.lowerBound
            params.param.sched_priority = Int32(priority)
            pthread_setschedparam(self, params.policy, &params.param)
        }
    }
    
    private func getSchedParams() -> (policy: Int32, param: sched_param) {
        let param = UnsafeMutablePointer<sched_param>.allocate(capacity: 1)
        let policy = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        defer { param.deallocate() }
        defer { policy.deallocate() }
        pthread_getschedparam(self, policy, param)
        return (policy.pointee, param.pointee)
    }
    
    private func priorityRange(for policy: Int32) -> Range<Float> {
        let min = sched_get_priority_min(policy)
        let max = sched_get_priority_max(policy)
        return Float(min)..<Float(max)
    }
}
