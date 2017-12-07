//
//  SKCacheItem.swift
//  SKParkCode
//
//  Created by SoalHunag on 2017/12/7.
//  Copyright © 2017年 SoalHunag. All rights reserved.
//

import Foundation
import SQLite

public var sqlite_key      = Expression<String>("key")
public var sqlite_data     = Expression<Data>("data")
public var sqlite_overdue  = Expression<TimeInterval>("overdue")

public struct SKCacheItem {
    
    public var key: String
    public var data: Data
    public var overdue: TimeInterval
    
    public init?(_ data: Data) {
        let dict = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String:Any]
        self.key = (dict?["key"] as? String) ?? ""
        self.overdue = (dict?["overdue"] as? TimeInterval) ?? TimeInterval(Int.max)
        self.data = (dict?["data"] as? Data) ?? Data()
    }
    
    public var toData: Data {
        let dict: [String : Any] = ["key":key, "overdue": overdue, "data": data]
        let adata = NSKeyedArchiver.archivedData(withRootObject: dict)
        return adata
    }
    
    public init(_ key: String, _ data: Data, _ overdue: TimeInterval) {
        self.key = key
        self.data = data
        self.overdue = overdue
    }
    
    public init(with sqlite_row: Row) {
        self.key = sqlite_row[sqlite_key]
        self.data = sqlite_row[sqlite_data]
        self.overdue = sqlite_row[sqlite_overdue]
    }
    
    public var setters: [Setter] {
        return [sqlite_key <- key, sqlite_data <- data, sqlite_overdue <- overdue]
    }
    
    public var description: String {
        return "\nkey:\(key), \noverdue:\(overdue), \ndata:\(data)"
    }
    
}
