//
//  PoCache.swift
//  KitDemo
//
//  Created by 黄中山 on 2018/7/15.
//  Copyright © 2018年 黄中山. All rights reserved.
//

import Foundation

class PoCache {
    
    // MARK: - Properties
    let name: String
    let memoryCache: PoMemoryCache<String, Data>
    let diskCache: PoDiskCache
    
    
    // MARK: - Inlitializers
    init(name: String = "", path: String) {
        if path.isEmpty { fatalError("PoCache error: path can't be empty.") }
        self.name = name
        self.memoryCache = PoMemoryCache<String, Data>()
        self.diskCache = PoDiskCache(path: path)
    }
    
    
    
    // MARK: - Methods
    
    func containsObject(for key: String) -> Bool {
        return memoryCache.containsObject(for: key) || diskCache.containsObject(for: key)
    }
    
    func containsObject(for key: String, completion: @escaping (String, Bool) -> Void) {
        if memoryCache.containsObject(for: key) {
            DispatchQueue.global(qos: .default).async {
                completion(key, true)
            }
        } else {
            diskCache.containsObject(for: key, completion: completion)
        }
    }
    
    func object(for key: String) -> Data? {
        if let value = memoryCache.object(for: key) {
            return value
        } else if let value = diskCache.object(for: key) {
            memoryCache.setObject(value, for: key)
            return value
        } else {
            return nil
        }
    }
    
    func object(for key: String, completion: @escaping (String, Data?) -> Void) {
        if let value = memoryCache.object(for: key) {
            DispatchQueue.global(qos: .default).async {
                completion(key, value)
            }
        } else {
            diskCache.object(for: key) { (key, value) in
                if value != nil && !self.memoryCache.containsObject(for: key) {
                    self.memoryCache.setObject(value!, for: key)
                }
                completion(key, value)
            }
        }
    }
    
    func setObject(_ object: Data, for key: String) {
        memoryCache.setObject(object, for: key, cost: object.count)
        diskCache.setObject(object, for: key)
    }
    
    func setObject(_ object: Data, for key: String, completion: @escaping () -> Void) {
        memoryCache.setObject(object, for: key, cost: object.count)
        diskCache.setObject(object, for: key, completion: completion)
    }
    
    func removeObject(for key: String) {
        memoryCache.removeObject(for: key)
        diskCache.removeObject(for: key)
    }
    
    func removeObject(for key: String, completion: @escaping (String) -> Void) {
        memoryCache.removeObject(for: key)
        diskCache.removeObject(for: key, completion: completion)
    }
    
    func removeAll() {
        memoryCache.removeAllObjects()
        diskCache.removeAllObjects()
    }
    
    func removeAll(completion: @escaping () -> Void) {
        memoryCache.removeAllObjects()
        diskCache.removeAllObjects(completion: completion)
    }
    
    func removeAll(progress: ((Int, Int) -> Void)?, completion: ((Bool) -> Void)?) {
        memoryCache.removeAllObjects()
        diskCache.removeAllObjects(progresee: progress, completion: completion)
    }
}
