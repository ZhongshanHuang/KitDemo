//
//  PoTextInput.swift
//  KitDemo
//
//  Created by 黄中山 on 2018/7/20.
//  Copyright © 2018年 黄中山. All rights reserved.
//

import UIKit

final class PoTextPosition: UITextPosition {
    
    // MARK: - Properties

    private(set) var offset: Int = 0
    private(set) var affinity: UITextStorageDirection
    
    
    // MARK: - Initializers
    
    init(offset: Int, affinity: UITextStorageDirection = .forward) {
        self.offset = offset
        self.affinity = affinity
    }
    
    
    // MARK: - Methods
    
    func compare(_ otherPosition: PoTextPosition) -> ComparisonResult {
        if offset < otherPosition.offset { return .orderedAscending }
        if offset > otherPosition.offset { return .orderedDescending }
        if affinity == .backward && otherPosition.affinity == .forward { return .orderedAscending }
        if affinity == .forward && otherPosition.affinity == .backward { return .orderedDescending }
        return .orderedSame
    }
    
    // MARK: - Equatable
    static func == (lhs: PoTextPosition, rhs: PoTextPosition) -> Bool {
        return lhs.offset == rhs.offset && lhs.affinity == rhs.affinity
    }
    
    override var description: String {
        return "offset: \(offset), affinity: \(affinity.rawValue)"
    }
}

final class PoTextRange: UITextRange {
    
    // MARK: - Properties
    private var _start: PoTextPosition
    override var start: PoTextPosition {
        get { return _start }
        set { _start = newValue }
    }
    
    private var _end: PoTextPosition
    override var end: PoTextPosition {
        get { return _end }
        set { _end = newValue }
    }
    
    override var isEmpty: Bool {
        return start.offset == end.offset
    }
    
    var asRange: NSRange {
        return NSRange(location: start.offset, length: end.offset - start.offset)
    }
    
    init(start: PoTextPosition, end: PoTextPosition) {
        if start.compare(end) == .orderedDescending {
            self._start = end
            self._end = start
        } else {
            self._start = start
            self._end = end
        }
    }
    
    convenience init(range: NSRange, affinity: UITextStorageDirection = .forward) {
        let start = PoTextPosition(offset: range.location, affinity: affinity)
        let end = PoTextPosition(offset: range.location + range.length, affinity: affinity)
        self.init(start: start, end: end)
    }
    
    convenience override init() {
        self.init(start: PoTextPosition(offset: 0), end: PoTextPosition(offset: 0))
    }
    
    override var description: String {
        return "start: (\(start))\n end: (\(end))"
    }
}



final class PoTextSelectionRect: UITextSelectionRect {
    
    // MARK: - Properties
    
    private var _rect: CGRect = .zero
    override var rect: CGRect {
        get { return _rect }
        set { _rect = newValue }
    }
    
    private var _writingDirection: UITextWritingDirection = .leftToRight
    override var writingDirection: UITextWritingDirection {
        get { return _writingDirection }
        set { _writingDirection = newValue }
    }
    
    private var _containsStart: Bool = false
    override var containsStart: Bool {
        get { return _containsStart }
        set { _containsStart = newValue }
    }
    
    private var _containsEnd: Bool = false
    override var containsEnd: Bool {
        get { return _containsEnd }
        set { _containsEnd = newValue }
    }
    
}
