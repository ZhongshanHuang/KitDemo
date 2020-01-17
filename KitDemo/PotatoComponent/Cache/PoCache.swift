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
    
    func containsObject(forKey key: String) -> Bool {
        return memoryCache.containsObject(forKey: key) || diskCache.containsObject(forKey: key)
    }
    
    func containsObject(forKey key: String, completion: @escaping (String, Bool) -> Void) {
        if memoryCache.containsObject(forKey: key) {
            DispatchQueue.global(qos: .default).async {
                completion(key, true)
            }
        } else {
            diskCache.containsObject(forKey: key, completion: completion)
        }
    }
    
    func object(forKey key: String) -> Data? {
        if let value = memoryCache.object(forKey: key) {
            return value
        } else if let value = diskCache.object(forKey: key) {
            memoryCache.setObject(value, forKey: key)
            return value
        } else {
            return nil
        }
    }
    
    func object(forKey key: String, completion: @escaping (String, Data?) -> Void) {
        if let value = memoryCache.object(forKey: key) {
            DispatchQueue.global(qos: .default).async {
                completion(key, value)
            }
        } else {
            diskCache.object(forKey: key) { (key, value) in
                if value != nil && !self.memoryCache.containsObject(forKey: key) {
                    self.memoryCache.setObject(value!, forKey: key)
                }
                completion(key, value)
            }
        }
    }
    
    func setObject(_ object: Data, forKey key: String) {
        memoryCache.setObject(object, forKey: key, cost: object.count)
        diskCache.setObject(object, forKey: key)
    }
    
    func setObject(_ object: Data, forKey key: String, completion: @escaping () -> Void) {
        memoryCache.setObject(object, forKey: key, cost: object.count)
        diskCache.setObject(object, forKey: key, completion: completion)
    }
    
    func removeObject(forKey key: String) {
        memoryCache.removeObject(forKey: key)
        diskCache.removeObject(forKey: key)
    }
    
    func removeObject(forKey key: String, completion: @escaping (String) -> Void) {
        memoryCache.removeObject(forKey: key)
        diskCache.removeObject(forKey: key, completion: completion)
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
