//
//  DiskFileManager.swift
//  CacheManager
//
//  Created by Fan Zhou on 2025/4/1.
//

import Foundation

public protocol DiskFileManagerProtocol {
    func fileExists(atPath path: String) -> Bool
    
    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey: Any]?) throws
    
    func contentsOfDirectory(atPath path: String) throws -> [String]
    
    func removeItem(at URL: URL) throws
    
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any]
    
    func createFile(atPath path: String, contents data: Data?, attributes attr: [FileAttributeKey: Any]?) -> Bool
    
    func contents(atPath path: String) -> Data?
}

public final class DiskFileManager: DiskFileManagerProtocol {
    private let fileManager: FileManager
    
    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    public func fileExists(atPath path: String) -> Bool {
        return fileManager.fileExists(atPath: path)
    }
    
    public func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey: Any]?) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: createIntermediates, attributes: attributes)
    }
    
    public func contentsOfDirectory(atPath path: String) throws -> [String] {
        return try fileManager.contentsOfDirectory(atPath: path)
    }
    
    public func removeItem(at URL: URL) throws {
        try fileManager.removeItem(at: URL)
    }
    
    public func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any] {
        return try fileManager.attributesOfItem(atPath: path)
    }
    
    public func createFile(atPath path: String, contents data: Data?, attributes attr: [FileAttributeKey: Any]?) -> Bool {
        return fileManager.createFile(atPath: path, contents: data, attributes: attr)
    }
    
    public func contents(atPath path: String) -> Data? {
        return fileManager.contents(atPath: path)
    }
}
