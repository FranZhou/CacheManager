//
//  MemoryCacheConfiguration.swift
//  CacheManager
//
//  Created by Fan Zhou on 2025/4/1.
//

import Foundation

public struct MemoryCacheConfiguration {
    public let cleanupInterval: TimeInterval?
    
    public let capacity: Int
    
    public let expirationPolicy: ExpirationPolicy
    
    public init(cleanupInterval: TimeInterval? = nil, capacity: Int, expirationPolicy: ExpirationPolicy) {
        self.cleanupInterval = cleanupInterval
        self.capacity = capacity
        self.expirationPolicy = expirationPolicy
    }
}
