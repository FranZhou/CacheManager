//
//  TimeProvider.swift
//  CacheManager
//
//  Created by Fan Zhou on 2025/4/1.
//

import Foundation

public protocol TimeProviderProtocol {
    var currentTime: Date { get }
}

public struct TimeProvider: TimeProviderProtocol {
    public var currentTime: Date {
        return Date()
    }
    
    public init() {}
}
