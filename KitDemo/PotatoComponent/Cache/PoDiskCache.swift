//
//  PoDiskCache.swift
//  KitDemo
//
//  Created by 黄中山 on 2018/7/11.
//  Copyright © 2018年 黄中山. All rights reserved.
//

import Foundation

final class PoDiskCache {
    
    // MARK: - Properties - [attribute]
    
    var name: String = ""
    let path: String
    let inlineThreshold: Int
    
    
    // MARK: - Properties - [limit]
    
    var countLimit: Int = Int.max
    var costLimit: Int = Int.max
    var ageLimit: Int = Int.max
    var freeDiskSpaceLimit: Int = 0
    var autoTrimInterval: TimeInterval = 60
    var isErrorLogsEnable: Bool {
        get {
            return _kv.isErrorLogsEnable
        }
        set {
            _kv.isErrorLogsEnable = newValue
        }
    }
    
    
    // MARK: - Properties - [private]
    
    let _kv: PoKVStorage
    let _lock: DispatchSemaphore = DispatchSemaphore(value: 1)
    let _queue: DispatchQueue = DispatchQueue(label: "com.potato.cache.disk.access", qos: .utility, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
    
    
    
    // MARK: - Inilitializers
    
    init(path: String, inlineThredhold: Int = 1024*20) { // 20kb
        self.path = path
        self.inlineThreshold = inlineThredhold
        self._kv = PoKVStorage(path: path)
    }
    
    
    
    // MARK: - Methods - [access]
    
    func containsObject(for key: String) -> Bool {
        _ = _lock.wait(timeout: .distantFuture)
        let contains = _kv.itemExists(for: key)
        _lock.signal()
        return contains
    }
    
    func containsObject(for key: String, completion: @escaping (String, Bool) -> Void) {
        _queue.async { [weak self] in
            guard let strongSelf = self else { completion(key, false); return }
            let contains = strongSelf.containsObject(for: key)
            completion(key, contains)
        }
    }
    
    func object(for key: String) -> Data? {
        _ = _lock.wait(timeout: .distantFuture)
        let item = _kv.getItem(for: key)
        _lock.signal()
        
        return item?.value
    }
    
    func object(for key: String, completion: @escaping (String, Data?) -> Void) {
        _queue.async { [weak self] in
            guard let strongSelf = self else { completion(key, nil); return }
            let data = strongSelf.object(for: key)
            completion(key, data)
        }
    }
    
    func setObject(_ object: Data, for key: String) {
        var filename: String?
        if object.count > inlineThreshold {
            filename = key.md5
        }
        _ = _lock.wait(timeout: .distantFuture)
        _kv.saveItem(with: key, value: object, filename: filename, extendedData: nil)
        _lock.signal()
    }
    
    func setObject(_ object: Data, for key: String, completion: @escaping () -> Void) {
        _queue.async { [weak self] in
            guard let strongSelf = self else { completion(); return }
            strongSelf.setObject(object, for: key)
            completion()
        }
    }
    
    func removeObject(for key: String) {
        _ = _lock.wait(timeout: .distantFuture)
        _kv.removeItem(for: key)
        _lock.signal()
    }
    
    func removeObject(for key: String, completion: @escaping (String) -> Void) {
        _queue.async { [weak self] in
            guard let strongSelf = self else { completion(key); return }
            strongSelf.removeObject(for: key)
            completion(key)
        }
    }
    
    func removeAllObjects() {
        _ = _lock.wait(timeout: .distantFuture)
        _kv.removeAllItems()
        _lock.signal()
    }
    
    func removeAllObjects(completion: @escaping () -> Void) {
        _queue.async { [weak self] in
            guard let strongSelf = self else { completion(); return }
            strongSelf.removeAllObjects()
            completion()
        }
    }
    
    func removeAllObjects(progresee: ((Int, Int) -> Void)?, completion: ((Bool) -> Void)?) {
        _queue.async { [weak self] in
            guard let strongSelf = self else { completion?(true); return }
            _ = strongSelf._lock.wait(timeout: .distantFuture)
            strongSelf._kv.removeAllItems(progress: progresee, end: completion)
            strongSelf._lock.signal()
        }
    }
    
    func totalCount() -> Int {
        _ = _lock.wait(timeout: .distantFuture)
        let count = _kv.getItemsCount()
        _lock.signal()
        return count
    }
    
    func totalCount(completion: @escaping (Int) -> Void) {
        _queue.async { [weak self] in
            guard let strongSelf = self else { completion(-1); return }
            let count = strongSelf.totalCount()
            completion(count)
        }
    }
    
    func totalCost() -> Int {
        _ = _lock.wait(timeout: .distantFuture)
        let cost = _kv.getItemsSize()
        _lock.signal()
        return cost
    }
    
    func totalCost(completion: @escaping (Int) -> Void) {
        _queue.async { [weak self] in
            guard let strongSelf = self else { completion(-1); return }
            let cost = strongSelf.totalCount()
            completion(cost)
        }
    }
    
    
    
    // MARK: - Methods - [trim]
    
    func trimToCount(_ count: Int) {
        _ = _lock.wait(timeout: .distantFuture)
        _trimToCount(count)
        _lock.signal()
    }
    
    func trimToCount(_ count: Int, completion: @escaping () -> Void) {
        _queue.async { [weak self] in
            guard let strongSelf = self else { completion(); return }
            strongSelf.trimToCount(count)
            completion()
        }
    }
    
    func trimToCost(_ cost: Int) {
        _ = _lock.wait(timeout: .distantFuture)
        _trimToCost(cost)
        _lock.signal()
    }
    
    func trimToCost(_ cost: Int, completion: @escaping () -> Void) {
        _queue.async { [weak self] in
            guard let strongSelf = self else { completion(); return }
            strongSelf.trimToCost(cost)
            completion()
        }
    }
    
    func trimToAge(_ age: Int) {
        _ = _lock.wait(timeout: .distantFuture)
        _trimToAge(age)
        _lock.signal()
    }
    
    func trimToAge(_ age: Int, completion: @escaping () -> Void) {
        _queue.async { [weak self] in
            guard let strongSelf = self else { completion(); return }
            strongSelf.trimToAge(age)
            completion()
        }
    }
    
    
    
    // MARK: - Methods - [private]
    
    private func _freeSpaceInDisk() -> Int {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            let space = attributes[FileAttributeKey.systemFreeSize] as! Int
            if space < 0 { return -1 }
            return space
        } catch {
            return -1
        }
    }
    
    private func _trimRecursively() {
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: DispatchTime.now() + autoTrimInterval) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf._trimBackground()
            strongSelf._trimRecursively()
        }
    }
    
    private func _trimBackground() {
        _queue.async { [weak self] in
            guard let strongSelf = self else { return }
            _ = strongSelf._lock.wait(timeout: .distantFuture)
            strongSelf._trimToCost(strongSelf.costLimit)
            strongSelf._trimToCount(strongSelf.countLimit)
            strongSelf._trimToAge(strongSelf.ageLimit)
            strongSelf._trimToFreeDiskSpace(strongSelf.freeDiskSpaceLimit)
            strongSelf._lock.signal()
        }
    }
    
    private func _trimToCount(_ count: Int) {
        if count >= Int.max { return }
        _kv.removeItemsToFitCount(count)
    }
    
    private func _trimToCost(_ cost: Int) {
        if cost >= Int.max { return }
        _kv.removeItemsToFitSize(cost)
    }
    
    private func _trimToAge(_ age: Int) {
        if age <= 0 {
            _kv.removeAllItems()
            return
        }
        let timestamp = Int(time(nil))
        if timestamp <= age { return }
        _kv.removeItemsEarlierThan(age)
    }
    
    private func _trimToFreeDiskSpace(_ space: Int) {
        if space == 0 { return }
        let totalBytes = _kv.getItemsSize()
        if totalBytes <= 0 { return }
        let diskFreeBytes = _freeSpaceInDisk()
        if diskFreeBytes < 0 { return }
        let needTrimBytes = space - diskFreeBytes
        if needTrimBytes <= 0 { return }
        var costLimit = totalBytes - needTrimBytes
        if costLimit < 0 { costLimit = 0 }
        _trimToCost(costLimit)
    }
    
}
