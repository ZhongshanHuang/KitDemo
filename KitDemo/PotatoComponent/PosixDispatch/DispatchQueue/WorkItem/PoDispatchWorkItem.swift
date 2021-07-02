//
//  PoDispatchWorkItem.swift
//  KitDemo
//
//  Created by 黄中山 on 2020/6/10.
//  Copyright © 2020 黄中山. All rights reserved.
//

import Foundation

struct PoDispatchWorkItemFlags: OptionSet {
    static let barrier = PoDispatchWorkItemFlags(rawValue: 1 << 0)
    static let enforceQoS = PoDispatchWorkItemFlags(rawValue: 1 << 1)
    let rawValue: Int
}

extension PoDispatchWorkItem {
    
    enum State {
        case ready, performing, completed, cancelled
    }
    
    enum WorkItemError: Swift.Error {
        case canceled
    }
    
}

class PoDispatchWorkItem<T> {
    
    typealias Flags = PoDispatchWorkItemFlags
    typealias Block = () throws -> T
    typealias Result = Swift.Result<T, Swift.Error>
    typealias Completion = (Result) -> Void
    
    let flags: Flags
    private let block: Block
    private let condition = PoCondition()
    private var result: Result?
    
    private var _state = State.ready
    var state: State {
        return condition.lockedPerform { _state }
    }
    
    var isCancelled: Bool {
        return condition.lockedPerform { _state == .cancelled }
    }
    
    init(flags: Flags = [], block: @escaping Block) {
        self.flags = flags
        self.block = block
    }
    
    func perform() {
        condition.lock()
        defer { condition.unlock() }
        
        if _state != .ready { return }
        _state = .performing
        condition.unlock()
        let result = Result(catching: block)
        condition.lock()
        if _state == .cancelled { return }
        self.result = result
        _state = .completed
        condition.broadcast()
        observers.forEach({ $0(result) })
        observers.removeAll()
    }
    
    func wait() {
        condition.lock()
        while _state == .ready || _state != .performing {
            condition.wait()
        }
        condition.unlock()
    }
    
    func await() throws -> T {
        condition.lock()
        defer { condition.unlock() }
        
        while _state != .cancelled {
            switch result {
            case .success(let value):
                return value
            case .failure(let error):
                throw error
            case .none:
                condition.wait()
            }
        }
        throw WorkItemError.canceled
    }
    
    func cancel() {
        condition.lock()
        defer { condition.unlock() }
        
        _state = .cancelled
        observers.removeAll()
        condition.broadcast()
    }
    
    // MARK: - Observers
    
    private var observers = [Completion]()
    
    func notify(flags: Flags = [], queue: PoDispatchQueue, execute: @escaping PoThread.Block) {
        condition.lock()
        observers.append({ result in
            queue.async(flags: flags, execute: execute)
        })
        condition.unlock()
    }
    
    func notify(flags: Flags = [], queue: PoDispatchQueue, execute: @escaping Completion) {
        condition.lock()
        observers.append({ result in
            queue.async(flags: flags) {
                execute(result)
            }
        })
        condition.unlock()
    }
    
    func notify(queue: PoDispatchQueue, execute: PoDispatchWorkItem) {
        condition.lock()
        observers.append({ _ in
            queue.async(execute: execute)
        })
        condition.unlock()
    }
}
