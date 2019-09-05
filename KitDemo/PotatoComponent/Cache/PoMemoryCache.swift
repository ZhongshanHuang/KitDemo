//
//  PoMemoryCache.swift
//  KitDemo
//
//  Created by 黄中山 on 2018/6/10.
//  Copyright © 2018年 黄中山. All rights reserved.
//

import UIKit


private let kPoMemoryCacheReleaseQueue: DispatchQueue = DispatchQueue(label: "com.potato.cache.memory.release", qos: .utility)


// MARK: - PoMemoryCache
final class PoMemoryCache<Key, Value> where Key : Hashable {
    
    // MARK: - Propertis - [Attribute]
    
    /** The name of cache. Default is nil. */
    var name: String?
    
    /** The number of objects in the cache. */
    var totalCount: Int {
        pthread_mutex_lock(&_lock)
        let count = _lru.totalCount
        pthread_mutex_unlock(&_lock)
        return count
    }
    
    /** The total cost of objects in the cache. */
    var totalCost: Int {
        pthread_mutex_lock(&_lock)
        let cost = _lru.totalCost
        pthread_mutex_unlock(&_lock)
        return cost
    }
    
    // MARK: - Properties - [Limit]
    
    /** The maximum number of objects the cache should hold. */
    var countLimit: Int = Int.max
    
    /** The maximum  total cost that the cache can hold. */
    var costLimit: Int = Int.max
    
    /** The maximum expiry time of objects in cache. */
    var ageLimit: TimeInterval = .greatestFiniteMagnitude
    
    /** The auto trim check time interval in seconds. */
    var autoTrimInterval: TimeInterval = 5.0
    
    /** If true, the cache will remove all objects when the app receives a memory warning. */
    var isShouldRemoveAllObjectsOnMemoryWarning: Bool = true
    
    /** If true the cache will remove all objects when the app enter background. */
    var isShouldRemoveAllObjectsWhenEnteringBackground: Bool = true
    
    /** The block will be executed when the app receive a memory warning. */
    var didReceiveMemoryWarningBlock: ((PoMemoryCache) -> Void)?
    
    /** The block will be executed when the app enter background. */
    var didEnterBackgroundBlock: ((PoMemoryCache) -> Void)?
    
    /** The key-value pair will be released on the main thread if true. otherwise on the background thread. */
    var isReleasedOnMainThread: Bool = false {
        didSet {
            _lru.isReleasedOnMainThread = isReleasedOnMainThread
        }
    }
    
    /** The key-value pair will be released asynchronously if true. */
    var isReleasedAsynchronously: Bool = true {
        didSet {
            _lru.isReleasedAsynchronously = isReleasedAsynchronously
        }
    }
    
    private var _lock: pthread_mutex_t = pthread_mutex_t()
    private let _lru: PoLinkedMap<Key, Value> = PoLinkedMap()
    private let _queue: DispatchQueue = DispatchQueue(label: "com.potato.cache.memory.access")
    
    init() {
        pthread_mutex_init(&_lock, nil)
        _trimRecursively()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(_appDidReceiveMemoryWarningNotification),
                                               name: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(_appDidEnterBackgroundNotification),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didReceiveMemoryWarningNotification,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didEnterBackgroundNotification,
                                                  object: nil)
        _lru.removeAll()
        pthread_mutex_destroy(&_lock)
    }
    
    // MARK: - Methods - [Access]
    
    /// Return true, when the cache contain the key-value pair
    func containsObject(for key: Key) -> Bool {
        pthread_mutex_lock(&_lock)
        let contains = _lru.dic.contains { (k, _) -> Bool in
            k == key
        }
        pthread_mutex_unlock(&_lock)
        return contains
    }
    
    /// Return the value when the key-value pair exist, else will return nil
    func object(for key: Key) -> Value? {
        pthread_mutex_lock(&_lock)
        if let nodeRef = _lru.dic[key] {
            nodeRef.pointee.time = CACurrentMediaTime()
            _lru.bringNodeToHead(nodeRef)
            pthread_mutex_unlock(&_lock)
            return nodeRef.pointee.value
        } else {
            pthread_mutex_unlock(&_lock)
            return nil
        }
    }
    
    /// The key-value pair will be stored.
    func setObject(_ anObject: Value, for key: Key, cost: Int = 0) {
        pthread_mutex_lock(&_lock)
        let now = CACurrentMediaTime()
        if let nodeRef = _lru.dic[key] {
            _lru.totalCost -= nodeRef.pointee.cost
            _lru.totalCost += cost
            nodeRef.pointee.cost = cost
            nodeRef.pointee.time = now
            nodeRef.pointee.value = anObject
            _lru.bringNodeToHead(nodeRef)
        } else {
            let node = PoLinkedMapNode<Key, Value>(key: key, value: anObject, cost: cost, time: now)
            let nodeRef = UnsafeMutablePointer<PoLinkedMapNode<Key, Value>>.allocate(capacity: 1)
            nodeRef.initialize(to: node)
            _lru.insertNodeAtHead(nodeRef)
        }
        
        if _lru.totalCost > costLimit {
            _queue.async {
                self.trimToCost(self.costLimit)
            }
        }
        
        if _lru.totalCount > countLimit {
            let nodeRef = _lru.removeTailNode()
            if _lru.isReleasedAsynchronously {
                let queue = _lru.isReleasedOnMainThread ? DispatchQueue.main : kPoMemoryCacheReleaseQueue
                queue.async {
                    nodeRef?.deinitialize(count: 1)
                    nodeRef?.deallocate()
                }
            } else if _lru.isReleasedOnMainThread && pthread_main_np() != 0 {
                DispatchQueue.main.async {
                    nodeRef?.deinitialize(count: 1)
                    nodeRef?.deallocate()
                }
            } else {
                nodeRef?.deinitialize(count: 1)
                nodeRef?.deallocate()
            }
        }
        pthread_mutex_unlock(&_lock)
    }
    
    func removeObject(for key: Key) {
        pthread_mutex_lock(&_lock)
        if let nodeRef = _lru.dic[key] {
            _lru.remove(nodeRef)

            if _lru.isReleasedAsynchronously {
                let queue = _lru.isReleasedOnMainThread ? DispatchQueue.main : kPoMemoryCacheReleaseQueue
                queue.async {
                    nodeRef.deinitialize(count: 1)
                    nodeRef.deallocate()
                }
            } else if _lru.isReleasedOnMainThread && pthread_main_np() != 0 {
                DispatchQueue.main.async {
                    nodeRef.deinitialize(count: 1)
                    nodeRef.deallocate()
                }
            } else {
                nodeRef.deinitialize(count: 1)
                nodeRef.deallocate()
            }
        }
        pthread_mutex_unlock(&_lock)
    }
    
    func removeAllObjects() {
        pthread_mutex_lock(&_lock)
        _lru.removeAll()
        pthread_mutex_unlock(&_lock)
    }
    
    // MARK: - Methods - [Trim]
    
    func trimToCount(_ count: Int) {
        if count == 0 {
            removeAllObjects()
            return
        }
        
        var finish = false
        pthread_mutex_lock(&_lock)
        if count == 0 {
            _lru.removeAll()
            finish = true
        } else if _lru.totalCount <= count {
            finish = true
        }
        pthread_mutex_unlock(&_lock)
        if finish { return }
        
        var holder: ContiguousArray<PoLinkedMap<Key, Value>.PoNodeRef> = []
        while !finish { // 相当于自旋锁
            if pthread_mutex_trylock(&_lock) == 0 {
                if _lru.totalCount > count {
                    if let nodeRef = _lru.removeTailNode() {
                        holder.append(nodeRef)
                    }
                } else {
                    finish = true
                }
                pthread_mutex_unlock(&_lock)
            } else {
                usleep(10 * 1000) //10 ms
            }
        }
        
        let queue = _lru.isReleasedOnMainThread ? DispatchQueue.main : kPoMemoryCacheReleaseQueue
        queue.async {
            for nodeRef in holder {
                nodeRef.deinitialize(count: 1)
                nodeRef.deallocate()
            }
        }
    }
    
    func trimToCost(_ cost: Int) {
        var finish = false
        pthread_mutex_lock(&_lock)
        if cost == 0 {
            _lru.removeAll()
            finish = true
        } else if _lru.totalCost <= cost {
            finish = true
        }
        pthread_mutex_unlock(&_lock)
        if finish { return }
        
        var holder: ContiguousArray<PoLinkedMap<Key, Value>.PoNodeRef> = []
        while !finish {
            if pthread_mutex_trylock(&_lock) == 0 {
                if _lru.totalCost > cost {
                    if let nodeRef = _lru.removeTailNode() {
                        holder.append(nodeRef)
                    }
                } else {
                    finish = true
                }
                pthread_mutex_unlock(&_lock)
            } else {
                usleep(10 * 1000) //10 ms
            }
        }
        
        let queue = _lru.isReleasedOnMainThread ? DispatchQueue.main : kPoMemoryCacheReleaseQueue
        queue.async {
            for nodeRef in holder {
                nodeRef.deinitialize(count: 1)
                nodeRef.deallocate()
            }
        }
    }
    
    func trimToAge(_ age: TimeInterval) {
        if ageLimit == .greatestFiniteMagnitude { return } // default -1
        
        var finish = false
        let now = CACurrentMediaTime()
        pthread_mutex_lock(&_lock)
        if ageLimit <= 0 {
            _lru.removeAll()
            finish = true
        } else if _lru._tail == nil || now - _lru._tail!.pointee.time <= ageLimit {
            finish = true
        }
        pthread_mutex_unlock(&_lock)
        if finish { return }
        
        var holder: ContiguousArray<PoLinkedMap<Key, Value>.PoNodeRef> = []
        while !finish {
            if pthread_mutex_trylock(&_lock) == 0 {
                if _lru._tail != nil && now - _lru._tail!.pointee.time > ageLimit {
                    if let nodeRef = _lru.removeTailNode() {
                        holder.append(nodeRef)
                    }
                } else {
                    finish = true
                }
                pthread_mutex_unlock(&_lock)
            } else {
                usleep(10 * 1000) //10 ms
            }
        }
        
        let queue = _lru.isReleasedOnMainThread ? DispatchQueue.main : kPoMemoryCacheReleaseQueue
        queue.async {
            for nodeRef in holder {
                nodeRef.deinitialize(count: 1)
                nodeRef.deallocate()
            }
        }

    }
    
    private func _trimRecursively() {
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + autoTrimInterval) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf._trimInBackground()
            strongSelf._trimRecursively()
        }
    }
    
    private func _trimInBackground() {
        _queue.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.trimToCost(strongSelf.costLimit)
            strongSelf.trimToCount(strongSelf.countLimit)
            strongSelf.trimToAge(strongSelf.ageLimit)
        }
    }
    
    // MARK: - Notification
    
    @objc
    private func _appDidReceiveMemoryWarningNotification() {
        didReceiveMemoryWarningBlock?(self)
        
        if isShouldRemoveAllObjectsOnMemoryWarning {
            removeAllObjects()
        }
    }
    
    @objc
    private func _appDidEnterBackgroundNotification() {
        didEnterBackgroundBlock?(self)
        
        if isShouldRemoveAllObjectsWhenEnteringBackground {
            removeAllObjects()
        }
    }
}


// MARK: - PoLinkedMapNode 经测试此中情况下使用struct作为节点，比class效率高很多

struct PoLinkedMapNode<Key, Value> {
    var prev: UnsafeMutablePointer<PoLinkedMapNode>?
    var next: UnsafeMutablePointer<PoLinkedMapNode>?
    
    var key: Key
    var value: Value
    var cost: Int
    var time: TimeInterval
    
    init(key: Key, value: Value, cost: Int, time: TimeInterval) {
        self.key = key
        self.value = value
        self.cost = cost
        self.time = time
    }
}


// MARK: - PoLinkedMap

final class PoLinkedMap<Key, Value> where Key : Hashable {
    
    typealias PoNode = PoLinkedMapNode<Key, Value>
    typealias PoNodeRef = UnsafeMutablePointer<PoNode>
    
    
    // MARK: - Properties - [public]
    lazy var dic: Dictionary<Key, PoNodeRef> = [:]
    var totalCost: Int = 0
    var totalCount: Int = 0
    
    fileprivate var _head: PoNodeRef?
    fileprivate var _tail: PoNodeRef?
    
    var isReleasedOnMainThread: Bool = false
    var isReleasedAsynchronously: Bool = true
    
    /// 确保nodeRef不在链表中，否则会导致内存泄漏问题
    func insertNodeAtHead(_ nodeRef: PoNodeRef) {
        dic[nodeRef.pointee.key] = nodeRef
        totalCost += nodeRef.pointee.cost
        totalCount += 1
        
        if _head != nil {
            nodeRef.pointee.next = _head
            _head?.pointee.prev = nodeRef
            _head = nodeRef
        } else {
            _tail = nodeRef
            _head = nodeRef
        }
    }
    
    func bringNodeToHead(_ nodeRef: PoNodeRef) {
        if _head == nodeRef { return }
        
        if _tail == nodeRef {
            _tail = nodeRef.pointee.prev
            _tail?.pointee.next = nil
        } else {
            nodeRef.pointee.next?.pointee.prev = nodeRef.pointee.prev
            nodeRef.pointee.prev?.pointee.next = nodeRef.pointee.next
        }
        
        nodeRef.pointee.next = _head
        nodeRef.pointee.prev = nil
        _head?.pointee.prev = nodeRef
        _head = nodeRef
    }
    
    func remove(_ nodeRef: PoNodeRef) {
        dic.removeValue(forKey: nodeRef.pointee.key)
        totalCost -= nodeRef.pointee.cost
        totalCount -= 1
        
        if nodeRef.pointee.next != nil {
            nodeRef.pointee.next?.pointee.prev = nodeRef.pointee.prev
        }
        
        if nodeRef.pointee.prev != nil {
            nodeRef.pointee.prev?.pointee.next = nodeRef.pointee.next
        }
        
        if _head == nodeRef {
            _head = nodeRef.pointee.next
        }
        
        if _tail == nodeRef {
            _tail = nodeRef.pointee.prev
        }
    }
    
    func removeTailNode() -> PoNodeRef? {
        if _tail == nil { return nil }
        let tail = _tail!
        dic.removeValue(forKey: tail.pointee.key)
        
        totalCost -= _tail!.pointee.cost
        totalCount -= 1
        if _head == _tail {
            _head = nil
            _tail = nil
        } else {
            _tail = tail.pointee.prev
            _tail?.pointee.next = nil
        }
        
        return tail
    }
    
    func removeAll() {
        totalCost = 0
        totalCount = 0
        _head = nil
        _tail = nil
        if dic.count > 0 {
            var holder = dic
            dic = [:]
            if isReleasedAsynchronously {
                let queue = isReleasedOnMainThread ? DispatchQueue.main : kPoMemoryCacheReleaseQueue
                queue.async {
                    for nodeRef in holder.values {
                        nodeRef.deinitialize(count: 1)
                        nodeRef.deallocate()
                    }
                }
            } else if isReleasedOnMainThread && pthread_main_np() != 0 {
                DispatchQueue.main.async {
                    for nodeRef in holder.values {
                        nodeRef.deinitialize(count: 1)
                        nodeRef.deallocate()
                    }
                }
            } else {
                for nodeRef in holder.values {
                    nodeRef.deinitialize(count: 1)
                    nodeRef.deallocate()
                }
            }
        }
    }
}


// MARK: 以下是使用class作为节点的实现，与struct作为节点性能对比差很多，所以注释掉

////
////  PoMemoryCache.swift
////  KitDemo
////
////  Created by 黄中山 on 2018/6/10.
////  Copyright © 2018年 黄中山. All rights reserved.
////
//
//import UIKit
//
//
//let PoMemoryCacheReleaseQueue: DispatchQueue = DispatchQueue(label: "com.potato.cache.memory.release", qos: .utility)
//
//
//// MARK: - PoMemoryCache
//final class PoMemoryCache<Key, Value> where Key : Hashable {
//
//    // MARK: - Propertis - [Attribute]
//
//    /** The name of cache. Default is nil. */
//    var name: String?
//
//    /** The number of objects in the cache. */
//    var totalCount: Int {
//        pthread_mutex_lock(&_lock)
//        let count = _lru.totalCount
//        pthread_mutex_unlock(&_lock)
//        return count
//    }
//
//    /** The total cost of objects in the cache. */
//    var totalCost: Int {
//        pthread_mutex_lock(&_lock)
//        let cost = _lru.totalCost
//        pthread_mutex_unlock(&_lock)
//        return cost
//    }
//
//    // MARK: - Properties - [Limit]
//
//    /** The maximum number of objects the cache should hold. */
//    var countLimit: Int = Int.max
//
//    /** The maximum  total cost that the cache can hold. */
//    var costLimit: Int = Int.max
//
//    /** The maximum expiry time of objects in cache. */
//    var ageLimit: TimeInterval = -1
//
//    /** The auto trim check time interval in seconds. */
//    var autoTrimInterval: TimeInterval = 5.0
//
//    /** The cache will remove all objects when the app receive a memory warning, if true. */
//    var isRemoveAllObjectsOnMemoryWarning: Bool = true
//
//    /** The cache will remove all objects when the app enter background. */
//    var isRemoveAllObjectsWhenEnteringBackground: Bool = true
//
//    /** The block will be executed when the app receive a memory warning. */
//    var didReceiveMemoryWarningBlock: ((PoMemoryCache) -> Void)?
//
//    /** The block will be executed when the app enter background. */
//    var didEnterBackgroundBlock: ((PoMemoryCache) -> Void)?
//
//    /** The key-value pair will be released on the main thread if true. otherwise on the background thread. */
//    var isReleasedOnMainThread: Bool = false {
//        didSet {
//            _lru.isReleasedOnMainThread = isReleasedOnMainThread
//        }
//    }
//
//    /** The key-value pair will be released asynchronously if true. */
//    var isReleasedAsynchronously: Bool = true {
//        didSet {
//            _lru.isReleasedAsynchronously = isReleasedAsynchronously
//        }
//    }
//
//    private var _lock: pthread_mutex_t = pthread_mutex_t()
//    private let _lru: PoLinkedMap<Key, Value>
//    private let _queue: DispatchQueue
//
//    init() {
//        pthread_mutex_init(&_lock, nil)
//        _lru = PoLinkedMap()
//        _queue = DispatchQueue(label: "com.potato.cache.memory.access")
//    }
//
//    deinit {
//        _lru.removeAll()
//        pthread_mutex_destroy(&_lock)
//    }
//
//    // MARK: - Methods - [Access]
//
//    func containsObject(for key: Key) -> Bool {
//        pthread_mutex_lock(&_lock)
//        let contains = _lru.dic.contains { (k, _) -> Bool in
//            k == key
//        }
//        pthread_mutex_unlock(&_lock)
//        return contains
//    }
//
//    func object(for key: Key) -> Value? {
//        pthread_mutex_lock(&_lock)
//        if let node = _lru.dic[key] {
//            node.time = CACurrentMediaTime()
//            _lru.bringNodeToHead(node)
//            pthread_mutex_unlock(&_lock)
//            return node.value
//        } else {
//            pthread_mutex_unlock(&_lock)
//            return nil
//        }
//    }
//
//    func setObject(_ anObject: Value, for key: Key, cost: Int = 0) {
//        pthread_mutex_unlock(&_lock)
//        let now = CACurrentMediaTime()
//        if let node = _lru.dic[key] {
//            _lru.totalCost -= node.cost
//            _lru.totalCost += cost
//            node.cost = cost
//            node.time = now
//            node.value = anObject
//            _lru.bringNodeToHead(node)
//        } else {
//            let node = PoLinkedMapNode<Key, Value>.init(key: key, value: anObject, cost: cost, time: now)
//            _lru.insertNodeAtHead(node)
//        }
//        if _lru.totalCost > costLimit {
//            _queue.async {
//                self.trimToCost(self.costLimit)
//            }
//        }
//
//        if _lru.totalCount > countLimit {
//            let node = _lru.removeTailNode()!
//            _lru.dic.removeValue(forKey: node.key)
//
//            if _lru.isReleasedAsynchronously {
//                let queue = _lru.isReleasedOnMainThread ? DispatchQueue.main : PoMemoryCacheReleaseQueue
//                queue.async {
//                    node.destroy()
//                }
//            } else if _lru.isReleasedOnMainThread && pthread_main_np() != 0 {
//                DispatchQueue.main.async {
//                    node.destroy()
//                }
//            } else {
//                node.destroy()
//            }
//        }
//
//        pthread_mutex_unlock(&_lock)
//    }
//
//    func removeObject(for key: Key) {
//        pthread_mutex_lock(&_lock)
//        if let node = _lru.dic.removeValue(forKey: key) {
//            _lru.remove(node)
//
//            if _lru.isReleasedAsynchronously {
//                let queue = _lru.isReleasedOnMainThread ? DispatchQueue.main : PoMemoryCacheReleaseQueue
//                queue.async {
//                    node.destroy()
//                }
//            } else if _lru.isReleasedOnMainThread && pthread_main_np() != 0 {
//                DispatchQueue.main.async {
//                    node.destroy()
//                }
//            } else {
//                node.destroy()
//            }
//        }
//        pthread_mutex_unlock(&_lock)
//    }
//
//    func removeAllObjects() {
//        pthread_mutex_lock(&_lock)
//        _lru.removeAll()
//        pthread_mutex_unlock(&_lock)
//    }
//
//    // MARK: - Methods - [Trim]
//
//    func trimToCount(_ count: Int) {
//        if count == 0 {
//            removeAllObjects()
//            return
//        }
//
//        var finish = false
//        pthread_mutex_lock(&_lock)
//        if count == 0 {
//            _lru.removeAll()
//            finish = true
//        } else if _lru.totalCount <= count {
//            finish = true
//        }
//        pthread_mutex_unlock(&_lock)
//        if finish { return }
//
//        var holder: Array<PoLinkedMap<Key, Value>.PoNode> = []
//        while !finish {
//            if pthread_mutex_trylock(&_lock) == 0 {
//                if _lru.totalCount > count {
//                    if let nodeRef = _lru.removeTailNode() {
//                        holder.append(nodeRef)
//                    }
//                } else {
//                    finish = true
//                }
//                pthread_mutex_unlock(&_lock)
//            } else {
//                usleep(10 * 1000) //10 ms
//            }
//        }
//
//        let queue = _lru.isReleasedOnMainThread ? DispatchQueue.main : PoMemoryCacheReleaseQueue
//        queue.async {
//            holder.removeAll()
//        }
//    }
//
//    func trimToCost(_ cost: Int) {
//        var finish = false
//        pthread_mutex_lock(&_lock)
//        if cost == 0 {
//            _lru.removeAll()
//            finish = true
//        } else if _lru.totalCost <= cost {
//            finish = true
//        }
//        pthread_mutex_unlock(&_lock)
//        if finish { return }
//
//        var holder: Array<PoLinkedMap<Key, Value>.PoNode> = []
//        while !finish {
//            if pthread_mutex_trylock(&_lock) == 0 {
//                if _lru.totalCost > cost {
//                    if let nodeRef = _lru.removeTailNode() {
//                        holder.append(nodeRef)
//                    }
//                } else {
//                    finish = true
//                }
//                pthread_mutex_unlock(&_lock)
//            } else {
//                usleep(10 * 1000) //10 ms
//            }
//        }
//
//        let queue = _lru.isReleasedOnMainThread ? DispatchQueue.main : PoMemoryCacheReleaseQueue
//        queue.async {
//            holder.removeAll()
//        }
//    }
//
//    func trimToAge(_ age: TimeInterval) {
//
//    }
//}
//

//// MARK: - PoLinkedMapNode
//final class PoLinkedMapNode<Key, Value> {
//    unowned var prev: PoLinkedMapNode?
//    unowned var next: PoLinkedMapNode?
//
//    var key: Key
//    var value: Value
//    var cost: Int
//    var time: TimeInterval
//
//    init(key: Key, value: Value, cost: Int, time: TimeInterval) {
//        self.key = key
//        self.value = value
//        self.cost = cost
//        self.time = time
//    }
//
//    func destroy() {}
//}
//
//
//// MARK: - PoLinkedMap
//final class PoLinkedMap<Key, Value> where Key : Hashable {
//
//    typealias PoNode = PoLinkedMapNode<Key, Value>
//
//    // MARK: - Properties - [public]
//    lazy var dic: Dictionary<Key, PoNode> = [:]
//    var totalCost: Int = 0
//    var totalCount: Int = 0
//
//    private var _head: PoNode?
//    private var _tail: PoNode?
//
//    var isReleasedOnMainThread: Bool = false
//    var isReleasedAsynchronously: Bool = true
//
//    deinit {
//        print("die on \(pthread_self())")
//    }
//
//    func insertNodeAtHead(_ node: PoNode) {
//        dic[node.key] = node
//        totalCost += node.cost
//        totalCount += 1
//
//        if _head != nil {
//            node.next = _head
//            _head?.prev = node
//            _head = node
//        } else {
//            _tail = node
//            _head = node
//        }
//    }
//
//    func bringNodeToHead(_ node: PoNode) {
//        if _head === node { return }
//
//        if _tail === node {
//            _tail = node.prev
//            _tail?.next = nil
//        } else {
//            node.next?.prev = node.prev
//            node.prev?.next = node.next
//        }
//
//        node.next = _head
//        node.prev = nil
//        _head?.prev = node
//        _head = node
//    }
//
//    func remove(_ node: PoNode) {
//        dic.removeValue(forKey: node.key)
//        totalCost -= node.cost
//        totalCount -= 1
//
//        if node.next != nil {
//            node.next?.prev = node.prev
//        }
//
//        if node.prev != nil {
//            node.prev?.next = node.next
//        }
//
//        if _head === node {
//            _head = node.next
//        }
//
//        if _tail === node {
//            _tail = node.prev
//        }
//    }
//
//    func removeTailNode() -> PoNode? {
//        if _tail == nil { return nil }
//        let tail = _tail!
//        dic.removeValue(forKey: tail.key)
//
//        totalCost -= _tail!.cost
//        totalCount -= 1
//        if _head === _tail {
//            _head = nil
//            _tail = nil
//        } else {
//            _tail = tail.prev
//            _tail?.next = nil
//        }
//
//        return tail
//    }
//
//    func removeAll() {
//        totalCost = 0
//        totalCount = 0
//        _head = nil
//        _tail = nil
//        if dic.count > 0 {
//            var holder = dic
//            dic = [:]
//            if isReleasedAsynchronously {
//                let queue = isReleasedOnMainThread ? DispatchQueue.main : PoMemoryCacheReleaseQueue
//                queue.async {
//                    holder.removeAll()
//                }
//            } else if isReleasedOnMainThread && pthread_main_np() != 0 {
//                DispatchQueue.main.async {
//                    holder.removeAll()
//                }
//            } else {
//                holder.removeAll()
//            }
//        }
//    }
//}
