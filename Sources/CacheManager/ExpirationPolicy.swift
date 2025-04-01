//
//  ExpirationPolicy.swift
//  CacheManager
//
//  Created by Fan Zhou on 2025/4/1.
//

import Foundation

public enum ExpirationPolicy: Codable {
    case sinceCreation(TimeInterval)
    case sinceLastAccess(TimeInterval)
    case never
}
