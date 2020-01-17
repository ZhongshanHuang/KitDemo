//
//  SortedSet.swift
//  KitDemo
//
//  Created by 黄山哥 on 2018/10/12.
//  Copyright © 2018 黄中山. All rights reserved.
//

import Foundation

protocol SortedSet: BidirectionalCollection, CustomStringConvertible where Element: Comparable {
    init()
    func contains(_ element: Element) -> Bool
    mutating func insert(_ newElement: Element) -> (inserted: Bool, memberAfterInsert: Element)
}

extension SortedSet {
    fileprivate static func compare(_ a: Any, _ b: Any) -> ComparisonResult {
        let a = a as! Element, b = b as! Element
        if a < b { return .orderedAscending }
        if a > b { return .orderedDescending }
        return .orderedSame
    }
    
    var description: String {
        let contents = self.lazy.map({"\($0)"}).joined(separator: ",")
        return "[\(contents)]"
    }
}


/* ------------------------------------SortedArray-------------------------------------- */

struct SortedArray<Element: Comparable>: SortedSet {
    
    private var storage: [Element] = []
    
    init() {}
}

extension SortedArray {
    
    /// 插入数据
    @discardableResult
    mutating func insert(_ newElement: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        let index = self.index(for: newElement)
        if index < count && storage[index] == newElement {
            return (false, newElement)
        }
        storage.insert(newElement, at: index)
        return (true, newElement)
    }
    
    /// 查找element的索引
    func index(of element: Element) -> Int? {
        var low = 0
        var up = count - 1
        var mid = 0
        while low <= up {
            mid = (up - low) / 2 + low
            let val = self[mid]
            if element < val {
                up = mid - 1
            } else if element > val {
                low = mid + 1
            } else {
                return mid
            }
        }
        return nil
    }
    
    /// 是否包含element
    func contains(_ element: Element) -> Bool {
        let index = self.index(for: element)
        return index < count && storage[index] == element
    }
    
    /// 对每个element执行body
    func forEach(_ body: (Element) throws -> Void) rethrows {
        try storage.forEach(body)
    }
    
    /// 返回一个有序数组
    func sorted() -> [Element] {
        return storage
    }
    
    private func index(for element: Element) -> Int {
        var start = 0
        var end = count
        
        while start < end {
            let mid = start + (end - start) / 2
            if element > storage[mid] {
                start = mid + 1
            } else {
                end = mid
            }
        }
        return start
    }
}

/// MARK: - RandomAccessCollection
extension SortedArray: RandomAccessCollection {
    typealias Indices = CountableRange<Int>
    
    var startIndex: Int { return storage.startIndex }
    var endIndex: Int { return storage.endIndex }
    
    subscript(index: Int) -> Element { return storage[index] }
}


/* -----------------------------------SortedSet--------------------------------------- */

struct OrderedSet<Element: Comparable>: SortedSet {
    private class Canary {}
    
    private var canary = Canary()
    private var storage: NSMutableOrderedSet = NSMutableOrderedSet()
    
    init() {}
    
    func forEach(_ body: (Element) -> Void) {
        storage.forEach { body($0 as! Element) }
    }
    
    func contains(_ element: Element) -> Bool {
        return index(of: element) != nil
    }
    
    func contains2(_ element: Element) -> Bool {
        return storage.contains(element) || index(of: element) != nil
    }
    
    func index(of element: Element) -> Int? {
        let index = storage.index(of: element, inSortedRange: NSRange(0..<storage.count), usingComparator: OrderedSet.compare)
        return index == NSNotFound ? nil : index
    }
    
    @discardableResult
    mutating func insert(_ newElement: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        let index = self.index(for: newElement)
        if index < storage.count, storage[index] as! Element == newElement {
            return (false, newElement)
        }
        makeUnique()
        storage.insert(newElement, at: index)
        return (true, newElement)
    }
}

extension OrderedSet: RandomAccessCollection {
    typealias Index = Int
    typealias Indices = CountableRange<Int>
    
    var startIndex: Int { return 0 }
    var endIndex: Int { return storage.count }
    subscript(i: Int) -> Element { return storage[i] as! Element }
}

extension OrderedSet {
    fileprivate mutating func makeUnique() {
        if !isKnownUniquelyReferenced(&canary) {
            storage = storage.mutableCopy() as! NSMutableOrderedSet
            canary = Canary()
        }
    }
    
    fileprivate func index(for value: Element) -> Int {
        return storage.index(of: value, inSortedRange: NSRange(0..<storage.count), options: .insertionIndex, usingComparator: OrderedSet.compare)
    }
}

/* ============================================================================================= */
/* https://github.com/apple/swift/blob/master/test/Prototypes/Algorithms.swift                  */
/* ============================================================================================ */

//protocol MutableCollectionAlgorithms: MutableCollection where SubSequence: MutableCollectionAlgorithms {
//    @discardableResult
//    mutating func rotate(shiftingToStart middle: Index) -> Index
//}
//
//extension Array: MutableCollectionAlgorithms {}
//extension ArraySlice: MutableCollectionAlgorithms {}
//extension Slice: MutableCollectionAlgorithms where Base: MutableCollection {}

extension MutableCollection {
    
    @inline(__always)
    mutating func _swapNonemptySubrangePrefixes(_ lhs: Range<Index>, _ rhs: Range<Index>) -> (Index, Index) {
        assert(!lhs.isEmpty)
        assert(!rhs.isEmpty)
        
        var p = lhs.lowerBound
        var q = rhs.lowerBound
        
        repeat {
            swapAt(p, q)
            formIndex(after: &p)
            formIndex(after: &q)
        } while p != lhs.upperBound && q != rhs.upperBound
        
        return (p, q)
    }
    
    
    @discardableResult
    mutating func rotate(shiftingToStart middle: Index) -> Index {
        var m = middle
        var s = startIndex
        let e = endIndex
        
        // Handle the trivial cases
        if s == m { return e }
        if m == e { return s }
        
        var ret = e
        while true {
            let (s1, m1) = _swapNonemptySubrangePrefixes(s..<m, m..<e)
            if m1 == e {
                if ret == e { ret = s1 }
                
                if s1 == m { break }
            }
            s = s1
            if s == m { m = m1 }
        }
        
        return ret
    }
    
}

extension MutableCollection where Self: BidirectionalCollection {
    @inline(__always)
    @discardableResult
    mutating func _reverseUntil(_ limit: Index) -> (Index, Index) {
        var f = startIndex
        var l = endIndex
        while f != limit && l != limit {
            formIndex(before: &l)
            swapAt(f, l)
            formIndex(after: &f)
        }
        return (f, l)
    }

    @discardableResult
    mutating func rotate(shiftingToStart middle: Index) -> Index {
        self[..<middle].reverse()
        self[middle...].reverse()
        let (p, q) = _reverseUntil(middle)
        self[p..<q].reverse()
        return middle == p ? q : p
    }

    func _gcd(_ m: Int, _ n: Int) -> Int {
        var (m, n) = (m, n)
        while n != 0 {
            let t = m % n
            m = n
            n = t
        }
        return m
    }
}

extension MutableCollection where Self: RangeReplaceableCollection {

    mutating func removeAllValue(where shouldRemove: (Element) -> Bool) {
        let suffixStart = _halfStablePartition(isSuffixElement: shouldRemove)
        removeSubrange(suffixStart...)
    }
}

extension MutableCollection {
    /// 将一个数组分成两半，前面部分保持原顺序不变
    mutating func _halfStablePartition(isSuffixElement: (Element) -> Bool) -> Index {
        guard var i = firstIndex(where: isSuffixElement) else { return endIndex }
        var j = index(after: i)
        while j < endIndex {
            if !isSuffixElement(self[j]) { swapAt(i, j); formIndex(after: &i) }
            formIndex(after: &j)
        }
        return i
    }
    
    /// 将一个数组分成两半，前后两半都保持原顺序不变
    mutating func _stablePartition(count n: Int, isSuffixElement: (Element) -> Bool) -> Index {
        if n == 0 { return startIndex }
        if n == 1 { return isSuffixElement(self[startIndex]) ? startIndex : endIndex }
        let h = n / 2, i = index(startIndex, offsetBy: h)
        let j = self[..<i]._stablePartition(count: h, isSuffixElement: isSuffixElement)
        let k = self[i...]._stablePartition(count: n - h, isSuffixElement: isSuffixElement)
        return self[j..<k].rotate(shiftingToStart: i)
    }
}

