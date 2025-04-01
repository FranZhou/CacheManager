//
//  DiskFileManagerMock.swift
//  CacheManager
//
//  Created by Fan Zhou on 2025/4/1.
//

import Foundation

import CacheManager

class DiskFileManagerMock: DiskFileManagerProtocol {
    var files: [String: Data] = [:]
    
    func fileExists(atPath path: String) -> Bool {
        return files[path] != nil
    }
    
    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey: Any]?) throws {
        files = [:]
    }
    
    func contentsOfDirectory(atPath path: String) throws -> [String] {
        return Array(files.keys)
    }
    
    func removeItem(at URL: URL) throws {
        files.removeValue(forKey: URL.path)
    }
    
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any] {
        return [.size: files[path]?.count ?? 0]
    }
    
    func createFile(atPath path: String, contents data: Data?, attributes attr: [FileAttributeKey: Any]?) -> Bool {
        files[path] = data
        return true
    }
    
    func contents(atPath path: String) -> Data? {
        return files[path]
    }
}
