//
//  SKCacheData.swift
//  SKParkCode
//
//  Created by SoalHunag on 2017/12/7.
//  Copyright © 2017年 SoalHunag. All rights reserved.
//

import Foundation
import SQLite

final public class SKCacheData: NSObject {
    
    static let shared = SKCacheData()
    
    var path: String
    
    fileprivate var db: Connection?
    fileprivate let table = Table("cache")
    
    init(_ path: String = NSHomeDirectory().appending("/Documents/SKCache/Database"), _ name: String = "cache.sqlite") {
        self.path = (path as NSString).appendingPathComponent(name)
        super.init()
        databaseConfig()
    }
    
}

fileprivate extension SKCacheData {
    
    fileprivate func databaseConfig() {
        
        let createDirectoryIfNotExist: (String) -> (Bool) = { directoryPath in
            if FileManager.default.fileExists(atPath: directoryPath) {
                return true
            }
            do {
                try FileManager.default.createDirectory(at:URL(fileURLWithPath:directoryPath), withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                print("create database directory failed:\(error.localizedDescription)")
                return false
            }
            return true
        }
        
        do {
            let directoryPath = (path as NSString).deletingLastPathComponent
            if !createDirectoryIfNotExist(directoryPath) {
                print("create directory failed")
            }
            try db = Connection(path)
            tableConfig()
        }
        catch {
            print("db config failed:\(error.localizedDescription)")
        }
    }
    
    fileprivate func tableConfig() {
        do {
            try db?.run(table.create(ifNotExists: true, block:{ t in
                t.column(sqlite_key, primaryKey: true)
                t.column(sqlite_data)
                t.column(sqlite_overdue)
            }))
        }
        catch {
            print("table config failed:\(error.localizedDescription)")
        }
    }
    
    fileprivate func sqlite_setters(_ item: SKCacheItem) -> [Setter] {
        return [sqlite_key <- item.key,
                sqlite_data <- item.data,
                sqlite_overdue <- item.overdue]
    }
    
}

public extension SKCacheData {
    
    public var costSize: Int {
        let manager = FileManager.default
        var fileSize:Double = 0
        do {
            let attr = try manager.attributesOfItem(atPath: path)
            fileSize = Double(attr[FileAttributeKey.size] as! UInt64)
            let dict = attr as NSDictionary
            fileSize = Double(dict.fileSize())
        } catch {
            print("database cache costSize failed:\(error.localizedDescription)")
        }
        return Int(fileSize)
    }
    
    @discardableResult
    public func store(data: Data, for key: String, overdue: TimeInterval) -> Bool {
        if let _ = query(for: key) {
            return update(SKCacheItem(key, data, overdue))
        }
        return insert(SKCacheItem(key, data, overdue))
    }
    
    @discardableResult
    public func insert(_ item: SKCacheItem) -> Bool {
        do {
            try self.db?.run(self.table.insert(item.setters))
        } catch {
            print("insert error:\(error.localizedDescription)")
            return false
        }
        return true
    }
    
    @discardableResult
    public func update(_ item: SKCacheItem) -> Bool {
        let table = self.table.filter(item.key == sqlite_key)
        do {
            try self.db?.run(table.update(sqlite_setters(item)))
        } catch {
            print("update error:\(error.localizedDescription)")
            return false
        }
        return true
    }
    
    @discardableResult
    public func query(for key: String) -> SKCacheItem? {
        let predicate = sqlite_key == key
        let query = self.table.filter(predicate).order(sqlite_overdue.desc).limit(1)
        guard let table = try? self.db?.prepare(query) else {
            return nil
        }
        return table?.flatMap({ SKCacheItem(with: $0) }).first
    }
    
    @discardableResult
    public func delete(for key: String) -> Bool {
        let predicate = sqlite_key == key
        let query = self.table.filter(predicate).order(sqlite_overdue.desc)
        do {
            try self.db?.run(query.delete())
        } catch {
            print("delete error:\(error.localizedDescription)")
            return false
        }
        return true
    }
    
    public func clear() {
        do {
            try self.db?.run(self.table.delete())
        } catch {
            print("delete error:\(error.localizedDescription)")
        }
    }
    
}
