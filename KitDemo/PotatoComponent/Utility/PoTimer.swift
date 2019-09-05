//
//  PoTimer.swift
//  KitDemo
//
//  Created by 黄中山 on 2018/5/22.
//  Copyright © 2018年 黄中山. All rights reserved.
//

import Foundation

final class PoTimer {
    
    // MARK: - Properties - [public]
    private(set) var repeats: Bool = false
    private(set) var timeInterval: TimeInterval
    private(set) var isValid: Bool = true
    
    // MARK: - Properties - [private]
    private weak var _target: AnyObject?
    private var _selector: Selector
    private let _lock: DispatchSemaphore = DispatchSemaphore(value: 1)
    private var _sourceTimer: DispatchSourceTimer? = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags.strict, queue: DispatchQueue.main)
    
    
    // MARK: - Factory Method
    static func timer(with timeInterval: TimeInterval, target: AnyObject, selector: Selector, repeats: Bool) -> Self {
        let timer = self.init(fireTime: 0, timeInterval: timeInterval, target: target, selector: selector, repeats: repeats)
        return timer
    }
    
    // MARK: - Initializer
    init(fireTime: TimeInterval, timeInterval: TimeInterval, target: AnyObject, selector: Selector, repeats: Bool) {
        self.repeats = repeats
        self.timeInterval = timeInterval
        self._target = target
        self._selector = selector
        // deadline 开始时间  repeating 重复次数
        _sourceTimer?.schedule(deadline: DispatchTime.now() + fireTime, repeating: timeInterval, leeway: .never)
        _sourceTimer?.setEventHandler { [weak self] in
            self?.fire()
        }
        _sourceTimer?.resume()
    }
    
    // MARK: - Methods
    
    // 开始执行
    func fire() {
        if !isValid { return }
        
        _lock.wait()
        if let target = _target {
            _lock.signal()
            _ = target.perform(_selector, with: self)
            if !repeats { invalidate() }
        } else {
            _lock.signal()
            invalidate()
        }
    }
    
    // 释放
    func invalidate() {
        _lock.wait()
        if isValid {
            _sourceTimer?.cancel()
            _sourceTimer = nil
            _target = nil
            isValid = false
        }
        _lock.signal()
    }
    
}
