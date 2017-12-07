//
//  SKCache.swift
//  SKCache
//
//  Created by SoalHunag on 2017/12/7.
//  Copyright © 2017年 SoalHuang. All rights reserved.
//

import Foundation

/// SKCache
final public class SKCache {
    
    public enum Types {
        case file       /// only cache as file
        case database   /// only cache in database
        case auto       /// cache as database or cache as file
    }
    
}

/// Sync
extension SKCache {
    
    @discardableResult
    public class func object(for key: String, by type: SKCache.Types = .auto) -> Data? {
        return SKCacheManager.manager.data(for: key, by: type)?.data
    }
    
    @discardableResult
    public class func set(data: Data?, for key: String, _ type: SKCache.Types = .auto, _ overdue: TimeInterval = TimeInterval(Int.max)) -> Bool {
        return SKCacheManager.manager.store(data: data, for: key, by: type, overdue)
    }
    
    @discardableResult
    public class func remove(for key: String, _ type: SKCache.Types = .auto) -> Bool {
        return SKCacheManager.manager.remove(for: key, by: type)
    }
    
    public class func removeAll(_ type: SKCache.Types = .auto) {
        SKCacheManager.manager.clear(for: type)
    }
    
}

/// Async
extension SKCache {
    
    public class func object(for key: String, by type: SKCache.Types = .auto, _ callback: @escaping (Data?) -> ()) {
        SKCacheManager.manager.dataRequest(for: key, by: type) { (item) in
            callback(item?.data)
        }
    }
    
    public class func set(data: Data?, for key: String, _ type: SKCache.Types = .auto, _ overdue: TimeInterval = TimeInterval(Int.max), _ callback: @escaping (Bool) -> ()) {
        SKCacheManager.manager.storeRequest(data: data, for: key, by: type, overdue, callback)
    }
    
    public class func remove(for key: String, _ type: SKCache.Types = .auto, _ callback: @escaping (Bool) -> ()) {
        SKCacheManager.manager.removeRequest(for: key, by: type, callback)
    }
    
    public class func removeAll(_ type: SKCache.Types = .auto, _ callback: @escaping () -> ()) {
        SKCacheManager.manager.clearRequest(for: type, callback)
    }
    
}
