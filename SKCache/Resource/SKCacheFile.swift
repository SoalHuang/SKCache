//
//  SKCacheFile.swift
//  SKParkCode
//
//  Created by SoalHunag on 2017/12/7.
//  Copyright © 2017年 SoalHunag. All rights reserved.
//

import Foundation

public class SKCacheFile: NSObject {
    
    static let shared = SKCacheFile()
    
    fileprivate var path: String
    
    init(_ path: String = NSHomeDirectory().appending("/Documents/SKCache/File")) {
        self.path = path
        super.init()
        setup()
    }
    
    fileprivate func setup() {
        if FileManager.default.fileExists(atPath: path) {
            return
        }
        do {
            try FileManager.default.createDirectory(at:URL(fileURLWithPath:path), withIntermediateDirectories: true, attributes: nil)
        }
        catch {
            print("create cache file failed:\(error.localizedDescription)")
        }
    }
    
}

public extension SKCacheFile {
    
    public var costSize: Int {
        let manager = FileManager.default
        var fileSize: Double = 0
        do {
            let attr = try manager.attributesOfItem(atPath: path)
            let dict = attr as NSDictionary
            fileSize = Double(dict.fileSize())
        } catch {
            print("file cache cost failed:\(error.localizedDescription)")
        }
        return Int(fileSize)
    }
    
    @discardableResult
    public func insert(data: Data, for key: String, overdue: TimeInterval) -> Bool {
        return insert(SKCacheItem(key, data, overdue))
    }
    
    @discardableResult
    public func insert(_ row: SKCacheItem) -> Bool {
        let data = row.toData
        do {
            let filePath = URL(fileURLWithPath: path.appending("/\(row.key)"))
            try data.write(to: filePath, options: .atomicWrite)
        } catch {
            print("write file:\(error.localizedDescription)")
            return false
        }
        return true
    }
    
    @discardableResult
    public func query(for key: String) -> SKCacheItem? {
        let filepath = path.appending("/\(key)")
        if !FileManager.default.fileExists(atPath: filepath) {
            return nil
        }
        do {
            let fileURL = URL(fileURLWithPath: filepath)
            let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
            return SKCacheItem(data)
        } catch {
            print("query file:\(error.localizedDescription)")
            return nil
        }
    }
    
    @discardableResult
    public func delete(for key: String) -> Bool {
        let filePath = path.appending("/\(key)")
        if !FileManager.default.isDeletableFile(atPath: filePath) {
            return false
        }
        do {
            try FileManager.default.removeItem(atPath: filePath)
        } catch {
            print("remove file:\(error.localizedDescription)")
            return false
        }
        return true
    }
    
    public func clear() {
        let filemngr = FileManager.default
        guard let subpaths = filemngr.subpaths(atPath: path) else {
            return
        }
        subpaths.forEach({ (subpath) in
            let realsubpath = path + "/" + subpath
            do {
                if !filemngr.isDeletableFile(atPath: realsubpath) {
                    return
                }
                try filemngr.removeItem(atPath: realsubpath)
            } catch {
                print("remove subpath file:\(error.localizedDescription)")
            }
        })
    }
    
}
