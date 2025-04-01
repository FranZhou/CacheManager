//
//  CacheItem.swift
//  CacheManager
//
//  Created by Fan Zhou on 2025/4/1.
//

import Foundation

struct CacheItem<Value> {
    let value: Value
    
    let creationTime: Date
    
    var lastAccessTime: Date
    
    let expirationPolicy: ExpirationPolicy
    
    init(value: Value, expirationPolicy: ExpirationPolicy, currentTime: Date) {
        self.value = value
        self.creationTime = currentTime
        self.lastAccessTime = currentTime
        self.expirationPolicy = expirationPolicy
    }
    
    func isExpired(currentTime: Date) -> Bool {
        switch expirationPolicy {
            case let .sinceCreation(interval):
                return currentTime.timeIntervalSince(creationTime) > interval
            case let .sinceLastAccess(interval):
                return currentTime.timeIntervalSince(lastAccessTime) > interval
            case .never:
                return false
        }
    }
    
    mutating func updateLastAccessTime(currentTime: Date) {
        lastAccessTime = currentTime
    }
}

extension CacheItem: Codable where Value: Codable {}
