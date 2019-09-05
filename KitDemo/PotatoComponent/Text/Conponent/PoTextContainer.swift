//
//  PoTextContainer.swift
//  KitDemo
//
//  Created by 黄中山 on 2018/9/13.
//  Copyright © 2018年 黄中山. All rights reserved.
//

import UIKit

/**
 Example:
 
 ┌─────────────────────────────┐  <------- container
 │                             │
 │    asdfasdfasdfasdfasdfa   <------------ container insets
 │    asdfasdfa   asdfasdfa    │
 │    asdfas         asdasd    │
 │    asdfa        <----------------------- container exclusion path
 │    asdfas         adfasd    │
 │    asdfasdfa   asdfasdfa    │
 │    asdfasdfasdfasdfasdfa    │
 │                             │
 └─────────────────────────────┘
 */

extension PoTextContainer {
    
    enum TruncationType {
        case none
        case head
        case middle
        case tail
    }
}

final class PoTextContainer: NSCopying {
    
    static let maxSize: CGSize = CGSize(width: 0x100000, height: 0x100000)
    
    // MARK: - Properties - [public]
    
    /// The constrained size. (if the size is larger than PoTextContainerMaxSize, it will be clipped.)
    private var _size: CGSize = .zero
    var size : CGSize {
        get {
            _ = _lock.wait(timeout: .distantFuture)
            let size = _size
            _lock.signal()
            return size
        }
        set {
            _ = _lock.wait(timeout: .distantFuture)
            if _path == nil {
                _size = newValue
                if newValue.width > PoTextContainer.maxSize.width {
                    _size.width = PoTextContainer.maxSize.width
                }
                if newValue.height > PoTextContainer.maxSize.height {
                    _size.height = PoTextContainer.maxSize.height
                }
            }
            _lock.signal()
        }
    }
    
    /// The insets for constrained size. The inset value should not be negative.
    private var _insets: UIEdgeInsets = .zero
    var insets: UIEdgeInsets {
        get {
            _ = _lock.wait(timeout: .distantFuture)
            let insets = _insets
            _lock.signal()
            return insets
        }
        set {
            _ = _lock.wait(timeout: .distantFuture)
            var value = newValue
            if value.top < 0 { value.top = 0 }
            if value.left < 0 { value.left = 0 }
            if value.bottom < 0 { value.bottom = 0 }
            if value.right < 0 { value.right = 0 }
            _insets = value
            _lock.signal()
        }
    }
    
    /// Custom constrained path. Set this property to ignore 'size' and 'insets'.
    private var _path: UIBezierPath?
    var path: UIBezierPath? {
        get {
            _ = _lock.wait(timeout: .distantFuture)
            let path = _path
            _lock.signal()
            return path
        }
        set {
            _ = _lock.wait(timeout: .distantFuture)
            _path = newValue?.copy() as? UIBezierPath
            if _path != nil {
                let bounds = _path!.bounds
                var size = bounds.size
                var insets = UIEdgeInsets.zero
                if bounds.minX < 0 { size.width += bounds.minX }
                if bounds.minX > 0 { insets.left = bounds.minX }
                if bounds.minY < 0 { size.height += bounds.minY }
                if bounds.minY > 0 { insets.top = bounds.minY }
                _size = size
                _insets = insets
            }
            _lock.signal()
        }
    }
    
    /// An array of UIBezierPath for path exclusion. Default is nil.
    private var _exclusionPaths: Array<UIBezierPath>?
    var exclusionPaths: Array<UIBezierPath>? {
        get {
            _ = _lock.wait(timeout: .distantFuture)
            let exclusionPaths = _exclusionPaths
            _lock.signal()
            return exclusionPaths
        }
        set {
            _ = _lock.wait(timeout: .distantFuture)
            _exclusionPaths = newValue
            _lock.signal()
        }
    }
    
    /// Path line width.
    private var _pathLineWidth: CGFloat = 0
    var pathLineWidth: CGFloat {
        get {
            _ = _lock.wait(timeout: .distantFuture)
            let pathLineWidth = _pathLineWidth
            _lock.signal()
            return pathLineWidth
        }
        set {
            _ = _lock.wait(timeout: .distantFuture)
            _pathLineWidth = newValue
            _lock.signal()
        }
    }
    
    /// True:(PathFillEvenOdd) Text is filled in the area that would be painted if the path were given to CGContextEOFillPath.
    /// False: (PathFillWindingNumber) Text is fill in the area that would be painted if the path were given to CGContextFillPath.
    /// Default is True;
    private var _isPathFillEvenOdd: Bool = true
    var isPathFillEvenOdd: Bool {
        get {
            _ = _lock.wait(timeout: .distantFuture)
            let isPathFillEvenOdd = _isPathFillEvenOdd
            _lock.signal()
            return isPathFillEvenOdd
        }
        set {
            _ = _lock.wait(timeout: .distantFuture)
            _isPathFillEvenOdd = newValue
            _lock.signal()
        }
    }
    
    /// Maximum number of rows, 0 means no limit.
    private var _maximumNumberOfRows: Int = 0
    var maximumNumberOfRows: Int {
        get {
            _ = _lock.wait(timeout: .distantFuture)
            let maximumNumberOfRows = _maximumNumberOfRows
            _lock.signal()
            return maximumNumberOfRows
        }
        set {
            _ = _lock.wait(timeout: .distantFuture)
            _maximumNumberOfRows = newValue
            _lock.signal()
        }
    }
    
    /// The line truncation type.
    private var _truncationType: TruncationType = .tail
    var truncationType: TruncationType {
        get {
            _ = _lock.wait(timeout: .distantFuture)
            let truncationType = _truncationType
            _lock.signal()
            return truncationType
        }
        set {
            _ = _lock.wait(timeout: .distantFuture)
            _truncationType = newValue
            _lock.signal()
        }
    }
    
    /// The truncation token. If nil, the layout will use '...'instead.
    private var _truncationToken: NSAttributedString?
    var truncationToken: NSAttributedString? {
        get {
            _ = _lock.wait(timeout: .distantFuture)
            let truncationToken = _truncationToken
            _lock.signal()
            return truncationToken
        }
        set {
            _ = _lock.wait(timeout: .distantFuture)
            _truncationToken = newValue
            _lock.signal()
        }
    }
    
    /// This modifier is applied to the line before the layout is completed,
    /// give you a chance to modify the line position.
    private var _linePositionModifyer: PoTextLinePositionModifier?
    var linePositionModifyer: PoTextLinePositionModifier? {
        get {
            _ = _lock.wait(timeout: .distantFuture)
            let linePositionModifyer = _linePositionModifyer
            _lock.signal()
            return linePositionModifyer
        }
        set {
            _ = _lock.wait(timeout: .distantFuture)
            _linePositionModifyer = newValue
            _lock.signal()
        }
    }
    
    
    // MARK: - Properties - [private]
    private let _lock: DispatchSemaphore = DispatchSemaphore(value: 1)
    
    
    // MARK: - Initializers
    init(size: CGSize = .zero, insets: UIEdgeInsets = .zero) {
        self.size = size
        self.insets = insets
    }
    
    init(path: UIBezierPath) {
        self.path = path
    }
    
    
    /// NSCoping
    func copy(with zone: NSZone? = nil) -> Any {
        let one = PoTextContainer()
        _ = _lock.wait(timeout: .distantFuture)
        one.size = _size
        one.insets = _insets
        one.path = _path
        one.exclusionPaths = _exclusionPaths
        one.pathLineWidth = _pathLineWidth
        one.isPathFillEvenOdd = _isPathFillEvenOdd
        one.maximumNumberOfRows = _maximumNumberOfRows
        one.truncationType = _truncationType
        one.truncationToken = _truncationToken
        one.linePositionModifyer = _linePositionModifyer?.copy() as? PoTextLinePositionModifier
        _lock.signal()
        return one
    }
    
}
