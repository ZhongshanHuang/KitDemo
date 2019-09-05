//
//  PoGestureRecognizer.swift
//  KitDemo
//
//  Created by 黄中山 on 2018/5/21.
//  Copyright © 2018年 黄中山. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

class PoGestureRecognizer: UIGestureRecognizer {
    
    enum PoGestureRecognizerState {
        case began
        case moved
        case ended
        case cancelled
    }

    
    // MARK: - Properties-[public]
    private(set) var startPoint: CGPoint = .zero /// start point
    private(set) var lastPoint: CGPoint = .zero /// last move point
    private(set) var currentPoint: CGPoint = .zero /// current move point
    
    /// The action closure invoked by every gesture event
    var action: ((PoGestureRecognizer, PoGestureRecognizerState) -> Void)?
    
    
    // MARK - Methods - [public]
    func cancel() {
        if state == .began || state == .changed {
            state = .cancelled
            action?(self, .cancelled)
        }
    }
    
    // MARK - Methods - [override]
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .began
        startPoint = touches.first?.location(in: view) ?? .zero
        currentPoint = startPoint
        action?(self, .began)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .changed
        currentPoint = touches.first?.location(in: view) ?? .zero
        action?(self, .moved)
        lastPoint = currentPoint
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .ended
        action?(self, .ended)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .cancelled
        action?(self, .cancelled)
    }
    
    override func reset() {
        state = .possible
    }
}
