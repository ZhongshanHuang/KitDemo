//
//  PoKeychainItem.swift
//  KitDemo
//
//  Created by 黄中山 on 2020/6/9.
//  Copyright © 2020 黄中山. All rights reserved.
//

import Foundation

struct PoKeychainItem {
    
    enum Error: Swift.Error {
        case noPassword
        case unexpectedPasswordData
        case unexpectedItemData
        case unhandledError
    }
    
    // MARK: - Properties
    
    let service: String
    let account: String
    let accessGroup: String?
    
    func read() throws -> String {
        var query = PoKeychainItem.query(service: service, account: account, accessGroup: accessGroup)
        query[kSecMatchLimit] = kSecMatchLimitOne
        query[kSecReturnAttributes] = kCFBooleanTrue
        query[kSecReturnData] = kCFBooleanTrue
        
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, $0)
        }
        
        if status == errSecItemNotFound {
            throw Error.noPassword
        }
        
        if status != noErr {
            throw Error.unhandledError
        }
        
        guard let existingItem = queryResult as? [CFString: AnyObject],
            let passwordData = existingItem[kSecValueData] as? Data,
            let password = String(data: passwordData, encoding: .utf8) else {
                throw Error.unexpectedPasswordData
        }
        
        return password
    }
    
    func save(_ password: String) throws {
        let encodedPassword = password.data(using: .utf8)
        
        do {
            try _ = read()
            
            var attributesToUpdate = [CFString: AnyObject]()
            attributesToUpdate[kSecValueData] = encodedPassword as AnyObject
            
            let query = PoKeychainItem.query(service: service, account: account, accessGroup: accessGroup)
            let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            if status != noErr {
                throw Error.unhandledError
            }
        } catch Error.noPassword {
            var query = PoKeychainItem.query(service: service, account: account, accessGroup: accessGroup)
            query[kSecValueData] = encodedPassword as AnyObject
            let status = SecItemAdd(query as CFDictionary, nil)
            if status != noErr {
                throw Error.unhandledError
            }
        }
    }
    
    func delete() throws {
        let query = PoKeychainItem.query(service: service, account: account, accessGroup: accessGroup)
        let status = SecItemDelete(query as CFDictionary)
        if status != noErr || status != errSecItemNotFound {
            throw Error.unhandledError
        }
    }
    
    
    private static func query(service: String, account: String, accessGroup: String? = nil) -> [CFString: AnyObject] {
        var res = [CFString: AnyObject]()
        res[kSecClass] = kSecClassGenericPassword // 该条item的类型
        res[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock // 屏幕锁定后不允许访问
        res[kSecAttrService] = service as AnyObject
        res[kSecAttrAccount] = account as AnyObject
        
        if let accessGroup = accessGroup {
            res[kSecAttrAccessGroup] = accessGroup as AnyObject
        }
        
        return res
    }
    
}
