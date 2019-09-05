//
//  PoKVStorage.swift
//  KitDemo
//
//  Created by 黄中山 on 2018/6/23.
//  Copyright © 2018年 黄中山. All rights reserved.
//

import Foundation
import UIKit.UIApplication


/*
 File:
 /path/
 /manifest.sqlite
 /manifest.sqlite-shm
 /manifest.sqlite-wal
 /data/
      /e10adc3949ba59abbe56e057f20f883e
      /e10adc3949ba59abbe56e057f20f883e
 /trash/
       /unused_file_or_folder
 
 SQL:
 create table if not exists manifest (
 key                 text,
 filename            text,
 size                integer,
 inline_data         blob,
 modification_time   integer,
 last_access_time    integer,
 extended_data       blob,
 primary key(key),
 );
 create index if not exists last_access_time_idx on manifest(last_access_time);
 */

private let kMaxErrorRetryCount: Int = 8
private let kMinRetryTimeInterval: TimeInterval = 2
private let kMaxPathLength: Int = numericCast(PATH_MAX) - 64
private let kDBFileName: String = "manifest.db"
private let kDBShmFileName: String = "manifest.sqlite-shm"
private let kDBWalFileName: String = "manifest.sqlite-wal"
private let kDataDirectoryName: String = "data"
private let kTrashDirectoryName: String = "trash"

final class PoKVStorageItem {
    var key: String = ""
    var size: Int = 0
    var modTime: Int = 0
    var accessTime: Int = 0
    
    var filename: String?
    var value: Data?
    var extendedData: Data?
}

/*
 PoKVStorage is a multi-thread unsafe disk cache tool.
    The value is stored as a file in file system, when value beyond 20kb.
    The value is stored in sqlite with blob type, when value within 20kb.
*/
final class PoKVStorage {
    
    enum StorageType {
        /** The value is stored as a file in file system. */
        case file
        /** The value is stored in sqlite with blob type. */
        case sqlite
        /** The value is stored in file system or sqlite based on your choice. */
        case mixed
    }
    
    // MARK: - Properties - [public]
    let path: String
    var isErrorLogsEnable: Bool = true

    
    // MARK: - Properties - [private]
    private let _dbPath: String
    private let _dataPath: String
    private let _trashPath: String
    
    private var _db: OpaquePointer?
    private var _dbStmtCache: [String: OpaquePointer]!
    private var _dbLastOpenErrorTime: TimeInterval = 0
    private var _dbOpenErrorCount: Int = 0
    
    private var _backgroundTaskID: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    
    
    
    // MARK: - Initializer
    init(path: String) {
        guard path.count > 0 || path.count <= kMaxPathLength else {
            fatalError("PoKVStorage init error: invalid path: [\(path)].")
        }
        self.path = path
        self._dataPath = (path as NSString).appendingPathComponent(kDataDirectoryName)
        self._trashPath = (path as NSString).appendingPathComponent(kTrashDirectoryName)
        self._dbPath = (path as NSString).appendingPathComponent(kDBFileName)
        
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(atPath: _dataPath, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(atPath: _trashPath, withIntermediateDirectories: true, attributes: nil)
        } catch (let error) {
            fatalError("PoKVStorage init error: [\(error.localizedDescription)].")
        }
        
        if !_dbOpen() || !_dbInitialize() {
            // db file may broken
            _dbClose()
            _reset() // rebuild
            if !_dbOpen() || !_dbInitialize() {
                fatalError("PoKVStorage init error: fail to open sqlite db.")
            }
        }
        _fileEmptyTrashInBackground()
    }
    
    deinit {
        _backgroundTaskID = UIApplication.shared.beginBackgroundTask() {
            UIApplication.shared.endBackgroundTask(self._backgroundTaskID)
        }
        _dbClose()
        if _backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask(_backgroundTaskID)
        }
    }
    
    
    
    // MARK: - Methods - [save item]
    
    @discardableResult
    func saveItem(_ item: PoKVStorageItem) -> Bool {
        if item.value == nil {
            PoDebugPrint("PoKVStorageItem.value can't be nil.")
            return false
        }
        return saveItem(with: item.key, value: item.value!, filename: item.filename, extendedData: item.extendedData)
    }
    
    @discardableResult
    func saveItem(with key: String, value: Data, filename: String? = nil, extendedData: Data? = nil) -> Bool {
        if key.isEmpty || value.isEmpty { return false }
        
        if filename != nil {
            if !_fileWrite(with: key, data: value) { return false }
            if !_dbSave(key: key, value: nil, filename: filename, extendedData: extendedData) {
                _fileDelete(with: filename!)
                return false
            }
            return true
        } else {
            return _dbSave(key: key, value: value, filename: nil, extendedData: extendedData)
        }
    }
    
    
    
    // MARK: - Methods - [remove item]
    
    @discardableResult
    func removeItem(for key: String) -> Bool {
        if key.isEmpty { return false }
        
        if let filename = _dbGetFilename(with: key) {
            _fileDelete(with: filename)
        }
        return _dbDeleteItem(with: key)
    }
    
    func removeItem(for keys: [String]) -> Bool {
        if keys.isEmpty { return false }
        
        if let filenames = _dbGetFilenameWithkeys(keys) {
            for filename in filenames {
                _fileDelete(with: filename)
            }
        }
        return _dbDeleteItemWithkeys(keys)
    }
    
    func removeItemsLargeThan(_ size: Int) -> Bool {
        if size == Int.max { return true }
        if size <= 0 { return removeAllItems() }
        
        if let filenames = _dbGetFilenamesWithSizeLargerThan(size) {
            for filename in filenames {
                if !_fileDelete(with: filename) {
                    return false
                }
            }
        }
        if _dbDeleteItemsWithSizeLargerThan(size) {
            _dbCheckPoint()
        }
        return true
    }
    
    @discardableResult
    func removeItemsEarlierThan(_ time: Int) -> Bool {
        if time <= 0 { return true }
        if time == Int.max { return removeAllItems() }
        
        if let filenames = _dbGetFilenamesWithTimeEarlierThan(time) {
            for filename in filenames {
                if !_fileDelete(with: filename) {
                    return false
                }
            }
        }
        if _dbDeleteItemsWithTimeEarlierThan(time) {
            _dbCheckPoint()
        }
        return true
    }
    
    @discardableResult
    func removeItemsToFitSize(_ maxSize: Int) -> Bool {
        if maxSize == Int.max { return true }
        if maxSize <= 0 { return removeAllItems() }
        
        var total = _dbGetTotalItemSize()
        if total <= 0 { return true }
        if total <= maxSize { return true }
        
        var success = false
        let perCount = 16
        repeat {
            if let items = _dbGetItemSizeInfoOrderByTimeAsc(with: perCount) {
                for item in items {
                    if total > maxSize {
                        if let filename = item.filename {
                            _fileDelete(with: filename)
                        }
                        success = _dbDeleteItem(with: item.key)
                        total -= item.size
                    } else {
                        break
                    }
                    if !success { break }
                }
            } else {
                success = (total < maxSize)
                break
            }
            
        } while total > maxSize && success
        
        if success {
            _dbCheckPoint()
        }
        return success
    }
    
    @discardableResult
    func removeItemsToFitCount(_ maxCount: Int) -> Bool {
        if maxCount == Int.max { return true }
        if maxCount <= 0 { return removeAllItems() }
        
        var total = _dbGetTotalItemCount()
        if total <= 0 { return true }
        if total <= maxCount { return true }
        
        var success = false
        let perCount = 16
        repeat {
            if let items = _dbGetItemSizeInfoOrderByTimeAsc(with: perCount) {
                for item in items {
                    if total > maxCount {
                        if let filename = item.filename {
                            _fileDelete(with: filename)
                        }
                        success = _dbDeleteItem(with: item.key)
                        total -= 1
                    }
                    if !success { break }
                }
            } else {
                success = (total < maxCount)
                break
            }
        } while total > maxCount && success
        
        if success {
            _dbCheckPoint()
        }
        return success
    }
   
    @discardableResult
    func removeAllItems() -> Bool {
        if !_dbClose() { return false }
        _reset()
        if !_dbOpen() { return false }
        if !_dbInitialize() { return false }
        return true
    }
    
    func removeAllItems(progress: ((Int, Int) -> Void)?, end: ((Bool) -> Void)?) {
        let total = _dbGetTotalItemCount()
        if total <= 0 {
            end?(false)
        } else {
            var left = total
            let perCount = 32
            var success = false
            repeat {
                if let items = _dbGetItemSizeInfoOrderByTimeAsc(with: perCount) {
                    for item in items {
                        if left > 0 {
                            if let filename = item.filename {
                                _fileDelete(with: filename)
                            }
                            success = _dbDeleteItem(with: item.key)
                            left -= 1
                        } else {
                            break
                        }
                    }
                    progress?(total - left, total)
                } else {
                    success = (left < total)
                    break
                }
                
            } while left > 0 && success
            if success {
                _dbCheckPoint()
            }
            end?(success)
        }
    }
    
    
    
    // MARK: - Methods - [get items]
    
    func getItem(for key: String) -> PoKVStorageItem? {
        if key.isEmpty { return nil }
        
        var item = _dbGetItem(with: key, excludeInlineData: false)
        if item != nil {
            _dbUpdateAccessTime(with: key)
            if let filename = item?.filename {
                item?.value = _fileRead(with: filename)
                if item?.value == nil {
                    _dbDeleteItem(with: key)
                    item = nil
                }
            }
        }
        return item
    }
    
    func getItemInfo(for key: String) -> PoKVStorageItem? {
        if key.isEmpty { return nil }
        
        return _dbGetItem(with: key, excludeInlineData: true)
    }
    
    func getItemValue(for key: String) -> Data? {
        if key.isEmpty { return nil }
        
        var value: Data?
        if let filename = _dbGetFilename(with: key) {
            value = _fileRead(with: filename)
            if value == nil {
                _dbDeleteItem(with: key)
            }
        } else {
            value = _dbGetValue(with: key)
        }
        return value
    }
    
    func getItemForKeys(_ keys: [String]) -> [PoKVStorageItem]? {
        if keys.isEmpty { return nil }
        
        if var items = _dbGetItemWithKeys(keys, excludeInlineData: false) {
            for (idx, item) in items.reversed().enumerated() {
                if let filename = item.filename {
                    item.value = _fileRead(with: filename)
                    if item.value == nil {
                        _dbDeleteItem(with: item.key)
                        items.remove(at: idx)
                    }
                }
            }
            if items.count > 0 {
                _dbUpdateAccessTimeWithkeys(keys)
                return items
            }
        }
        return nil
    }
    
    func getItemInfoForKeys(_ keys: [String]) -> [PoKVStorageItem]? {
        if keys.isEmpty { return nil }
        
        return _dbGetItemWithKeys(keys, excludeInlineData: true)
    }
    
    func getItemValueForKeys(_ keys: [String]) -> [String: Data]? {
        guard let items = getItemForKeys(keys)  else { return nil }
        
        var kv = [String: Data]()
        for item in items {
            if item.value != nil {
                kv[item.key] = item.value!
            }
        }
        return kv.count > 0 ? kv : nil
    }
    
    
    
    // MARK: - Methods - [storages status]
    
    func itemExists(for key: String) -> Bool {
        if key.isEmpty { return false }
        return _dbGetItemCount(with: key) > 0
    }
    
    func getItemsCount() -> Int {
        return _dbGetTotalItemCount()
    }
    
    func getItemsSize() -> Int {
        return _dbGetTotalItemSize()
    }
    
    
    
    // MARK: - Methods - [private]
    
    /// Delete all files and empty in background.
    /// Make sure the db is closed.
    private func _reset() {
        do {
            try FileManager.default.removeItem(atPath: (path as NSString).appendingPathComponent(kDBFileName))
            try FileManager.default.removeItem(atPath: (path as NSString).appendingPathComponent(kDBShmFileName))
            try FileManager.default.removeItem(atPath: (path as NSString).appendingPathComponent(kDBWalFileName))
            _fileMoveAllToTrash()
            _fileEmptyTrashInBackground()
        } catch (let error) {
            PoDebugPrint(error.localizedDescription)
        }
    }
    
    
}


// MARK: - file operator
extension PoKVStorage {
    
    @discardableResult
    private func _fileWrite(with filename: String, data: Data) -> Bool {
        let path = (_dataPath as NSString).appendingPathComponent(filename)
        do {
            try data.write(to: URL(fileURLWithPath: path))
            return true
        } catch (let error) {
            PoDebugPrint(error.localizedDescription)
            return false
        }
    }
    
    @discardableResult
    private func _fileRead(with filename: String) -> Data? {
        let path = (_dataPath as NSString).appendingPathComponent(filename)
        do {
            return try Data(contentsOf: URL(fileURLWithPath: path))
        } catch (let error) {
            PoDebugPrint(error.localizedDescription)
            return nil
        }
    }
    
    @discardableResult
    private func _fileDelete(with filename: String) -> Bool {
        let path = (_dataPath as NSString).appendingPathComponent(filename)
        do {
            try FileManager.default.removeItem(atPath: path)
            return true
        } catch (let error) {
            PoDebugPrint(error.localizedDescription)
            return false
        }
    }
    
    @discardableResult
    private func _fileMoveAllToTrash() -> Bool {
        let uuidRef = CFUUIDCreate(nil)
        let uuid = CFUUIDCreateString(nil, uuidRef)! as String
        let tmpPath = (_trashPath as NSString).appendingPathComponent(uuid)
        do {
            try FileManager.default.moveItem(atPath: _dataPath, toPath: tmpPath)
            try FileManager.default.createDirectory(atPath: _dataPath, withIntermediateDirectories: true, attributes: nil)
            return true
        } catch (let error) {
            PoDebugPrint(error.localizedDescription)
            return false
        }
    }
    
    private func _fileEmptyTrashInBackground() {
        let trashPath = _trashPath
        DispatchQueue.global(qos: .background).async {
            let manager = FileManager()
            do {
                let directoryContents = try manager.contentsOfDirectory(atPath: trashPath)
                for path in directoryContents {
                    let fullPath = (trashPath as NSString).appendingPathComponent(path)
                    try manager.removeItem(atPath: fullPath)
                }
            } catch (let error) {
                PoDebugPrint(error.localizedDescription)
            }
        }
    }
}


// MARK: - db operator
extension PoKVStorage {
    
    private func _dbOpen() -> Bool {
        if _db != nil { return true }
        
        let result = sqlite3_open_v2(_dbPath, &_db, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, nil)
        if result == SQLITE_OK {
            _dbStmtCache = [:]
            _dbLastOpenErrorTime = 0
            _dbOpenErrorCount = 0
            return true
        } else {
            _db = nil
            _dbStmtCache = nil
            _dbLastOpenErrorTime = CACurrentMediaTime()
            _dbOpenErrorCount += 1
            if isErrorLogsEnable {
                PoDebugPrint("sqlite open failed: \(result).")
            }
            return false
        }
    }
    
    @discardableResult
    private func _dbClose() -> Bool {
        if _db == nil { return true }
        
        var result: Int32 = 0
        var stmtFinalized = false
        var retry = false
        
        _dbStmtCache = nil // release those cached stmts
        
        repeat {
            retry = false
            result = sqlite3_close_v2(_db)
            if result == SQLITE_BUSY || result == SQLITE_LOCKED { // Some stmts have not be finalized.
                if !stmtFinalized {
                    var stmt: OpaquePointer?
                    stmt = sqlite3_next_stmt(_db, nil) // Find the stmt that has not be finalized.
                    while stmt != nil  {
                        sqlite3_finalize(stmt)
                        retry = true
                        stmt = sqlite3_next_stmt(_db, nil)
                    }
                    stmtFinalized = true
                }
            } else if result != SQLITE_OK {
                if isErrorLogsEnable {
                    PoDebugPrint("sqlite close failed: \(result).")
                }
                return false
            }
        } while retry
        
        _db = nil
        return true
    }
    
    private func _dbCheck() -> Bool {
        if _db == nil {
            if _dbOpenErrorCount < kMaxErrorRetryCount && CACurrentMediaTime() - _dbLastOpenErrorTime > kMinRetryTimeInterval {
                return _dbOpen() && _dbInitialize()
            } else {
                return false
            }
        }
        return true
    }
    
    private func _dbInitialize() -> Bool {
        let sql = "pragma journal_mode = wal; pragma synchronous = normal; create table if not exists manifest (key text, filename text, size integer, inline_data blob, modification_time integer, last_access_time integer, extended_data blob, primary key(key)); create index if not exists last_access_time_idx on manifest(last_access_time);"
        return _dbExecute(sql)
    }
    
    private func _dbCheckPoint() {
        if !_dbCheck() { return }
        sqlite3_wal_checkpoint(_db, nil)
    }
    
    private func _dbExecute(_ sql: String) -> Bool {
        if sql.isEmpty { return false }
        if !_dbCheck() { return false }
        
        var pError: UnsafeMutablePointer<Int8>?
        let result = sqlite3_exec(_db, sql, nil, nil, &pError)
        if pError != nil {
            let errmsg = String(cString: pError!)
            PoDebugPrint("sqlite execute error: \(errmsg).")
            sqlite3_free(pError)
        }
        
        return result == SQLITE_OK
    }
    
    private func _dbPrepareStmt(_ sql: String) -> OpaquePointer? {
        if sql.isEmpty || _dbCheck() == false {
            return nil
        }
        var stmt = _dbStmtCache[sql]
        if stmt != nil  {
            sqlite3_reset(stmt)
        } else {
            let result = sqlite3_prepare_v2(_db, sql, -1, &stmt, nil)
            if result != SQLITE_OK {
                if isErrorLogsEnable {
                    let pError = sqlite3_errmsg(_db)
                    let errmsg = String(cString: pError!)
                    PoDebugPrint("sqlite stmt prepare error: \(errmsg).")
                }
                return nil
            }
            _dbStmtCache[sql] = stmt!
        }
        return stmt
    }
    
    
    /// - Returns: string like "?, ?, ?"
    private func _dbJoinedkeys(_ count: Int) -> String {
        var str = ""
        for i in 0..<count {
            str += "?"
            if i + 1 != count {
                str += ","
            }
        }
        return str
    }
    
    private func _dbBindJoinedKeys(_ keys: [String], stmt: OpaquePointer, from index: Int) {
        for i in 0..<keys.count {
            sqlite3_bind_text(stmt, Int32(index + i), keys[i], -1, nil)
        }
    }
    
    private func _dbSave(key: String, value: Data?, filename: String?, extendedData: Data?) -> Bool {
        let sql = "insert or replace into manifest (key, filename, size, inline_data, modification_time, last_access_time, extended_data) values (?1, ?2, ?3, ?4, ?5, ?6, ?7);"
        guard let stmt = _dbPrepareStmt(sql) else { return false }
        
        let timestamp = Int32(time(nil))
        sqlite3_bind_text(stmt, 1, key, -1, unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self))
        sqlite3_bind_text(stmt, 2, filename, -1, unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self))
        sqlite3_bind_int(stmt, 3, Int32(value?.count ?? 0))
        
        if value != nil {
            _ = value!.withUnsafeBytes { (pt) -> Void in
                sqlite3_bind_blob(stmt, 4, unsafeBitCast(pt, to: UnsafeRawPointer.self), Int32(value!.count), unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self))
            }
        } else {
            sqlite3_bind_blob(stmt, 4, nil, 0, nil)
        }
        sqlite3_bind_int(stmt, 5, timestamp)
        sqlite3_bind_int(stmt, 6, timestamp)
        
        if extendedData != nil {
            _ = extendedData!.withUnsafeBytes { (pt) -> Void in
                sqlite3_bind_blob(stmt, 7, unsafeBitCast(pt, to: UnsafeRawPointer.self), Int32(extendedData!.count), unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self))
            }
        } else {
            sqlite3_bind_blob(stmt, 7, nil, 0, nil)
        }
        
        let result = sqlite3_step(stmt)
        if result != SQLITE_DONE {
            if isErrorLogsEnable {
                let pError = sqlite3_errmsg(_db)
                let errmsg = String(cString: pError!)
                PoDebugPrint("sqlite insert error: \(errmsg).")
            }
            return false
        }
        return true
    }
    
    @discardableResult
    private func _dbUpdateAccessTime(with key: String) -> Bool {
        let sql = "update manifest set last_access_time = ?1 where key = ?2;"
        guard let stmt = _dbPrepareStmt(sql) else { return false }
        
        sqlite3_bind_int(stmt, 1, Int32(time(nil)))
        sqlite3_bind_text(stmt, 2, key, -1, nil)
        let result = sqlite3_step(stmt)
        if result != SQLITE_DONE {
            if isErrorLogsEnable {
                let pError = sqlite3_errmsg(_db)
                let errmsg = String(cString: pError!)
                PoDebugPrint("sqlite insert error: \(errmsg).")
            }
            return false
        }
        return true
    }
    
    @discardableResult
    private func _dbUpdateAccessTimeWithkeys(_ keys: [String]) -> Bool {
        if !_dbCheck() { return false }
        
        let timestamp = Int32(time(nil))
        let sql = "update manifest set last_access_time = \(timestamp) where key in (\(_dbJoinedkeys(keys.count)));"
        
        var stmt: OpaquePointer?
        var result = sqlite3_prepare_v2(_db, sql, -1, &stmt, nil)
        if result != SQLITE_OK {
            if isErrorLogsEnable {
                let pError = sqlite3_errmsg(_db)
                let errmsg = String(cString: pError!)
                PoDebugPrint("sqlite stmt prepare error: \(errmsg).")
            }
            return false
        }
        _dbBindJoinedKeys(keys, stmt: stmt!, from: 1)
        result = sqlite3_step(stmt)
        sqlite3_finalize(stmt)
        if result != SQLITE_DONE {
            if isErrorLogsEnable {
                let pError = sqlite3_errmsg(_db)
                let errmsg = String(cString: pError!)
                PoDebugPrint("sqlite update error: \(errmsg).")
            }
            return false
        }
        return true
    }
    
    @discardableResult
    private func _dbDeleteItem(with key: String) -> Bool {
        let sql = "delete from manifest where key = ?1;"
        guard let stmt = _dbPrepareStmt(sql) else { return false }
        
        sqlite3_bind_text(stmt, 1, key, -1, nil)
        let result = sqlite3_step(stmt)
        if result != SQLITE_DONE {
            if isErrorLogsEnable {
                let pError = sqlite3_errmsg(_db)
                let errmsg = String(cString: pError!)
                PoDebugPrint("sqlite delete error: \(errmsg).")
            }
            return false
        }
        return true
    }
    
    @discardableResult
    private func _dbDeleteItemWithkeys(_ keys: [String]) -> Bool {
        if !_dbCheck() { return false }
        
        let sql = "delete from manifest where key in (\(_dbJoinedkeys(keys.count)));"
        var stmt: OpaquePointer?
        var result = sqlite3_prepare_v2(_db, sql, -1, &stmt, nil)
        if result != SQLITE_OK {
            if isErrorLogsEnable {
                let pError = sqlite3_errmsg(_db)
                let errmsg = String(cString: pError!)
                PoDebugPrint("sqlite stmt prepare error: \(errmsg).")
            }
            return false
        }
        _dbBindJoinedKeys(keys, stmt: stmt!, from: 1)
        result = sqlite3_step(stmt)
        sqlite3_finalize(stmt)
        if result != SQLITE_DONE {
            if isErrorLogsEnable {
                let pError = sqlite3_errmsg(_db)
                let errmsg = String(cString: pError!)
                PoDebugPrint("sqlite delete error: \(errmsg).")
            }
            return false
        }
        return true
    }
    
    @discardableResult
    private func _dbDeleteItemsWithSizeLargerThan(_ size: Int) -> Bool {
        let sql = "delete from manifest where size > ?1;"
        guard let stmt = _dbPrepareStmt(sql) else { return false }
        
        sqlite3_bind_int(stmt, 1, Int32(size))
        let result = sqlite3_step(stmt)
        if result != SQLITE_DONE {
            if isErrorLogsEnable {
                let pError = sqlite3_errmsg(_db)
                let errmsg = String(cString: pError!)
                PoDebugPrint("sqlite delete error: \(errmsg).")
            }
            return false
        }
        return true
    }
    
    @discardableResult
    private func _dbDeleteItemsWithTimeEarlierThan(_ time: Int) -> Bool {
        let sql = "delete from manifest where last_access_time < ?1;"
        guard let stmt = _dbPrepareStmt(sql) else { return false }
        
        sqlite3_bind_int(stmt, 1, Int32(time))
        let result = sqlite3_step(stmt)
        if result != SQLITE_DONE {
            if isErrorLogsEnable {
                let pError = sqlite3_errmsg(_db)
                let errmsg = String(cString: pError!)
                PoDebugPrint("sqlite delete error: \(errmsg).")
            }
            return false
        }
        return true
    }
    
    private func _dbGetItem(from stmt: OpaquePointer, excludeInlineData: Bool) -> PoKVStorageItem {
        let key = sqlite3_column_text(stmt, 0)
        let filename = sqlite3_column_text(stmt, 1)
        let size = sqlite3_column_int(stmt, 2)
        let inline_data = excludeInlineData ? nil : sqlite3_column_blob(stmt, 3)
        let inline_data_bytes = excludeInlineData ? 0 : sqlite3_column_bytes(stmt, 3)
        let modification_time = sqlite3_column_int(stmt, 4)
        let last_access_time = sqlite3_column_int(stmt, 5)
        let extended_data = sqlite3_column_blob(stmt, 6)
        let extended_data_bytes = sqlite3_column_bytes(stmt, 6)
        
        let item = PoKVStorageItem()
        if key != nil {
            item.key = String(cString: key!)
        }
        if filename != nil {
            item.filename = String(cString: filename!)
        }
        item.size = Int(size)
        if inline_data_bytes > 0 && inline_data != nil {
            item.value = Data(bytes: inline_data!, count: Int(inline_data_bytes))
        }
        item.modTime = Int(modification_time)
        item.accessTime = Int(last_access_time)
        if extended_data_bytes > 0 && extended_data != nil {
            item.extendedData = Data(bytes: extended_data!, count: Int(extended_data_bytes))
        }
        return item
    }
    
    private func _dbGetItem(with key: String, excludeInlineData: Bool) -> PoKVStorageItem? {
        if !_dbCheck() { return nil }
        let sql = excludeInlineData ? "select key, filename, size, modification_time, last_access_time, extended_data from manifest where key = ?1;" : "select key, filename, size, inline_data, modification_time, last_access_time, extended_data from manifest where key = ?1;"
        guard let stmt = _dbPrepareStmt(sql) else { return nil }
        
        sqlite3_bind_text(stmt, 1, key, -1, nil)
        let result = sqlite3_step(stmt)
        if result == SQLITE_ROW {
            return _dbGetItem(from: stmt, excludeInlineData: excludeInlineData)
        } else {
            if result != SQLITE_DONE {
                if isErrorLogsEnable {
                    let pError = sqlite3_errmsg(_db)
                    let errmsg = String(cString: pError!)
                    PoDebugPrint("sqlite query error: \(errmsg).")
                }
            }
            return nil
        }
    }
    
    private func _dbGetItemWithKeys(_ keys: [String], excludeInlineData: Bool) -> [PoKVStorageItem]? {
        if !_dbCheck() { return nil }
        var sql: String
        if excludeInlineData {
            sql = "select key, filename, size, modification_time, last_access_time, extended_data from manifest where key in (\(_dbJoinedkeys(keys.count)));"
        } else {
            sql = "select key, filename, size, inline_data, modification_time, last_access_time, extended_data from manifest where key in (\(_dbJoinedkeys(keys.count)));"
        }
        
        var stmt: OpaquePointer?
        var result = sqlite3_prepare_v2(_db, sql, -1, &stmt, nil)
        if result != SQLITE_OK {
            if isErrorLogsEnable {
                let pError = sqlite3_errmsg(_db)
                let errmsg = String(cString: pError!)
                PoDebugPrint("sqlite stmt prepare error: \(errmsg).")
            }
            return nil
        }
        
        _dbBindJoinedKeys(keys, stmt: stmt!, from: 1)
        
        var items: [PoKVStorageItem]? = []
        while true {
            result = sqlite3_step(stmt)
            if result == SQLITE_ROW {
                let item = _dbGetItem(from: stmt!, excludeInlineData: excludeInlineData)
                items?.append(item)
            } else if result == SQLITE_DONE {
                break
            } else {
                if isErrorLogsEnable {
                    let pError = sqlite3_errmsg(_db)
                    let errmsg = String(cString: pError!)
                    PoDebugPrint("sqlite query error: \(errmsg).")
                }
                items = nil
                break
            }
        }
        sqlite3_finalize(stmt)
        return items
    }
    
    private func _dbGetValue(with key: String) -> Data? {
        let sql = "select inline_data from manifest where key = ?1;"
        guard let stmt = _dbPrepareStmt(sql) else { return nil }
        
        sqlite3_bind_text(stmt, 1, key, -1, nil)
        let result = sqlite3_step(stmt)
        if result == SQLITE_ROW {
            let inline_data = sqlite3_column_blob(stmt, 0)
            let inline_data_bytes = sqlite3_column_bytes(stmt, 0)
            if inline_data_bytes > 0 && inline_data != nil {
                return Data(bytes: inline_data!, count: Int(inline_data_bytes))
            }
        } else {
            if result != SQLITE_DONE {
                if isErrorLogsEnable {
                    let pError = sqlite3_errmsg(_db)
                    let errmsg = String(cString: pError!)
                    PoDebugPrint("sqlite query error: \(errmsg).")
                }
            }
        }
        return nil
    }
    
    private func _dbGetFilename(with key: String) -> String? {
        let sql = "select filename from manifest where key = ?1;"
        guard let stmt = _dbPrepareStmt(sql) else { return nil }
        
        sqlite3_bind_text(stmt, 1, key, -1, nil)
        let result = sqlite3_step(stmt)
        if result == SQLITE_ROW {
            let fileName = sqlite3_column_text(stmt, 0)
            if fileName != nil {
                return String(cString: fileName!)
            }
        } else {
            if result != SQLITE_DONE {
                if isErrorLogsEnable {
                    let pError = sqlite3_errmsg(_db)
                    let errmsg = String(cString: pError!)
                    PoDebugPrint("sqlite query error: \(errmsg).")
                }
            }
        }
        return nil
    }
    
    private func _dbGetFilenameWithkeys(_ keys: [String]) -> [String]? {
        if !_dbCheck() { return nil }
        
        let sql = "select filename from manifest where key in (\(_dbJoinedkeys(keys.count)));"
        var stmt: OpaquePointer?
        var result = sqlite3_prepare_v2(_db, sql, -1, &stmt, nil)
        if result != SQLITE_OK {
            if isErrorLogsEnable {
                let pError = sqlite3_errmsg(_db)
                let errmsg = String(cString: pError!)
                PoDebugPrint("sqlite stmt prepare error: \(errmsg).")
            }
            return nil
        }
        _dbBindJoinedKeys(keys, stmt: stmt!, from: 1)
        var filenames: [String]? = []
        while true {
            result = sqlite3_step(stmt)
            if result == SQLITE_ROW {
                if let filename = sqlite3_column_text(stmt, 0) {
                    filenames?.append(String(cString: filename))
                }
            } else if result == SQLITE_DONE {
                break
            } else {
                if isErrorLogsEnable {
                    let pError = sqlite3_errmsg(_db)
                    let errmsg = String(cString: pError!)
                    PoDebugPrint("sqlite query error: \(errmsg).")
                }
                filenames = nil
                break
            }
        }
        sqlite3_finalize(stmt)
        return filenames
    }
    
    private func _dbGetFilenamesWithSizeLargerThan(_ size: Int) -> [String]? {
        let sql = "select filename from manifest where size > ?1;"
        guard let stmt = _dbPrepareStmt(sql) else { return nil }
        sqlite3_bind_int(stmt, 1, Int32(size))
        
        var filenames: [String]? = []
        while true {
            let result = sqlite3_step(stmt)
            if result == SQLITE_ROW {
                if let filename = sqlite3_column_text(stmt, 0) {
                    filenames?.append(String(cString: filename))
                }
            } else if result == SQLITE_DONE {
                break
            } else {
                if isErrorLogsEnable {
                    let pError = sqlite3_errmsg(_db)
                    let errmsg = String(cString: pError!)
                    PoDebugPrint("sqlite query error: \(errmsg).")
                }
                filenames = nil
                break
            }
        }
        return filenames
    }
    
    private func _dbGetFilenamesWithTimeEarlierThan(_ time: Int) -> [String]? {
        let sql = "select filename from manifest where last_access_time < ?1;"
        guard let stmt = _dbPrepareStmt(sql) else { return nil }
        sqlite3_bind_int(stmt, 1, Int32(time))
        
        var filenames: [String]? = []
        while true {
            let result = sqlite3_step(stmt)
            if result == SQLITE_ROW {
                if let filename = sqlite3_column_text(stmt, 0) {
                    filenames?.append(String(cString: filename))
                }
            } else if result == SQLITE_DONE {
                break
            } else {
                if isErrorLogsEnable {
                    let pError = sqlite3_errmsg(_db)
                    let errmsg = String(cString: pError!)
                    PoDebugPrint("sqlite query error: \(errmsg).")
                }
                filenames = nil
                break
            }
        }
        return filenames
    }
    
    private func _dbGetItemSizeInfoOrderByTimeAsc(with limit: Int) -> [PoKVStorageItem]? {
        let sql = "select key, filename, size from manifest order by last_access_time asc limit ?1;"
        guard let stmt = _dbPrepareStmt(sql) else { return nil }
        sqlite3_bind_int(stmt, 1, Int32(limit))
        
        var items: [PoKVStorageItem]? = []
        while true {
            let result = sqlite3_step(stmt)
            if result == SQLITE_ROW {
                let key = sqlite3_column_text(stmt, 0)
                let filename = sqlite3_column_text(stmt, 1)
                let size = sqlite3_column_int(stmt, 2)
                if key != nil {
                    let item = PoKVStorageItem()
                    item.key = String(cString: key!)
                    item.filename = filename != nil ? String(cString: filename!) : nil
                    item.size = Int(size)
                    items?.append(item)
                }
            } else if result == SQLITE_DONE {
                break
            } else {
                if isErrorLogsEnable {
                    let pError = sqlite3_errmsg(_db)
                    let errmsg = String(cString: pError!)
                    PoDebugPrint("sqlite query error: \(errmsg).")
                }
                items = nil
                break
            }
        }
        return items
    }
    
    private func _dbGetItemCount(with key: String) -> Int {
        let sql = "select count(key) from manifest where key = ?1;"
        guard let stmt = _dbPrepareStmt(sql) else { return -1 }
        sqlite3_bind_text(stmt, 1, key, -1, nil)
        
        let result = sqlite3_step(stmt)
        if result != SQLITE_ROW {
            if isErrorLogsEnable {
                let pError = sqlite3_errmsg(_db)
                let errmsg = String(cString: pError!)
                PoDebugPrint("sqlite query error: \(errmsg).")
            }
            return -1
        }
        let count = sqlite3_column_int(stmt, 0)
        return Int(count)
    }
    
    private func _dbGetTotalItemSize() -> Int {
        let sql = "select sum(size) from manifest;"
        guard let stmt = _dbPrepareStmt(sql) else { return -1 }
        
        let result = sqlite3_step(stmt)
        if result != SQLITE_ROW {
            if isErrorLogsEnable {
                let pError = sqlite3_errmsg(_db)
                let errmsg = String(cString: pError!)
                PoDebugPrint("sqlite query error: \(errmsg).")
            }
            return -1
        }
        let sum = sqlite3_column_int(stmt, 0)
        return Int(sum)
    }
    
    private func _dbGetTotalItemCount() -> Int {
        let sql = "select count(*) from manifest;"
        guard let stmt = _dbPrepareStmt(sql) else { return -1 }
        
        let result = sqlite3_step(stmt)
        if result != SQLITE_ROW {
            if isErrorLogsEnable {
                let pError = sqlite3_errmsg(_db)
                let errmsg = String(cString: pError!)
                PoDebugPrint("sqlite query error: \(errmsg).")
            }
            return -1
        }
        let count = sqlite3_column_int(stmt, 0)
        return Int(count)
    }
}
