//
//  DiskCacheConfiguration.swift
//  CacheManager
//
//  Created by Fan Zhou on 2025/4/1.
//

import Foundation

public struct DiskCacheConfiguration {
    public let cleanupInterval: TimeInterval?
    
    public let cacheDirectory: URL
    
    public let expirationPolicy: ExpirationPolicy
    
    public init(cleanupInterval: TimeInterval?, cacheDirectory: URL, expirationPolicy: ExpirationPolicy) {
        self.cleanupInterval = cleanupInterval
        self.cacheDirectory = cacheDirectory
        self.expirationPolicy = expirationPolicy
    }
}
