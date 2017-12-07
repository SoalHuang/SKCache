//
//  SKCacheManager.swift
//  SKParkCode
//
//  Created by SoalHunag on 2017/12/7.
//  Copyright © 2017年 SoalHunag. All rights reserved.
//

import Foundation
import SQLite

final public class SKCacheManager: NSObject {
    
    /// default disk cache limit is 100mb, databse cache limit is 20mb
    public static let manager = SKCacheManager()
    
    /// task queue
    fileprivate let queue = DispatchQueue(label: "com.putao.park.cache.manager.queue")
    
    /// bite, database cache data size limit
    fileprivate var databaseDataSizeLimit: Int = 1024
    
    /// callback queue
    fileprivate var callbackQueue = DispatchQueue.main
    
    /// init with disk cache limit & databse cache limit, databaseDataSizeLimit default is 1024, callbackQueue default is main queue
    public init(databaseDataSizeLimit: Int = 1024, _ callbackQueue: DispatchQueue? = DispatchQueue.main) {
        super.init()
        self.databaseDataSizeLimit = databaseDataSizeLimit
    }
    
}

// MARK: Sync
extension SKCacheManager {
    
    /// disk cache total cost
    public var diskCost: Int {
        return SKCacheFile.shared.costSize
    }
    
    /// database cache total cost
    public var databaseCost: Int {
        return SKCacheData.shared.costSize
    }
    
    /// clear cache, if type is .auto, its will clear database cache and disk cache
    public func clear(for type: SKCache.Types = .auto) {
        switch type {
        case .auto:
            SKCacheData.shared.clear()
            SKCacheFile.shared.clear()
        case .database:
            SKCacheData.shared.clear()
        case .file:
            SKCacheFile.shared.clear()
        }
    }
    
    /// get cache by key and type, if type is .auto, its will search database cache at first, if not found, then search disk cache
    @discardableResult
    public func data(for key: String, by type: SKCache.Types = .auto) -> SKCacheItem? {
        switch type {
        case .auto:
            if let item = SKCacheFile.shared.query(for: key) {
                return item
            }
            return SKCacheData.shared.query(for: key)
        case .database:
            return SKCacheData.shared.query(for: key)
        case .file:
            return SKCacheFile.shared.query(for: key)
        }
    }
    
    /// store cache, if data is nil, remove data for key by type
    @discardableResult
    public func store(data: Data?, for key: String, by type: SKCache.Types = .auto, _ overdue: TimeInterval) -> Bool {
        guard let `data` = data else {
            return self.remove(for: key, by: type)
        }
        switch type {
        case .auto:
            if data.count > self.databaseDataSizeLimit {
                return SKCacheFile.shared.insert(data: data, for: key, overdue: overdue)
            } else {
                return SKCacheData.shared.store(data: data, for: key, overdue: overdue)
            }
        case .database:
            return SKCacheData.shared.store(data: data, for: key, overdue: overdue)
        case .file:
            return SKCacheFile.shared.insert(data: data, for: key, overdue: overdue)
        }
    }
    
    /// remove cache by key and type, if type is .auto, its will remove data from databse cache and disk cache
    @discardableResult
    public func remove(for key: String, by type: SKCache.Types = .auto) -> Bool {
        switch type {
        case .auto:
            return SKCacheData.shared.delete(for: key) || SKCacheFile.shared.delete(for: key)
        case .database:
            return SKCacheData.shared.delete(for: key)
        case .file:
            return SKCacheFile.shared.delete(for: key)
        }
    }
    
}

// MARK: Async
extension SKCacheManager {
    
    /// clear cache, if type is .auto, its will clear database cache and disk cache
    public func clearRequest(for type: SKCache.Types = .auto, _ callback: (() -> ())? = nil) {
        queue.async { [weak self] in
            guard let `self` = self else { return }
            self.clear(for: type)
            if let execute = callback {
                self.callbackQueue.async(execute: execute)
            }
        }
    }
    
    /// get cache by key and type, if type is .auto, its will search database cache at first, if not found, then search disk cache
    public func dataRequest(for key: String, by type: SKCache.Types = .auto, _ callback: ((SKCacheItem?) -> ())? = nil) {
        queue.async { [weak self] in
            guard let `self` = self else { return }
            let item = self.data(for: key, by: type)
            self.callbackQueue.async(execute: {
                callback?(item)
            })
        }
    }
    
    /// store cache, if data is nil, remove data for key by type
    public func storeRequest(data: Data?, for key: String, by type: SKCache.Types = .auto, _ overdue: TimeInterval, _ callback: ((Bool) -> (Void))? = nil) {
        guard let `data` = data else {
            self.removeRequest(for: key, by: type, callback)
            return
        }
        queue.async { [weak self] in
            guard let `self` = self else { return }
            let item = self.store(data: data, for: key, by: type, overdue)
            self.callbackQueue.async(execute: {
                callback?(item)
            })
        }
    }
    
    /// remove cache by key and type, if type is .auto, its will remove data from databse cache and disk cache
    public func removeRequest(for key: String, by type: SKCache.Types = .auto, _ callback: ((Bool) -> ())? = nil) {
        queue.async { [weak self] in
            guard let `self` = self else { return }
            let item = self.remove(for: key, by: type)
            self.callbackQueue.async(execute: {
                callback?(item)
            })
        }
    }
    
}
