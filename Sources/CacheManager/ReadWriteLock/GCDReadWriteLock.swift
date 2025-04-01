//
//  Untitled.swift
//  CacheManager
//
//  Created by Fan Zhou on 2025/4/1.
//

import Foundation

public class GCDReadWriteLock: ReadWriteLockProtocol {
    private let queue: DispatchQueue
    
    public init(queue: DispatchQueue) {
        self.queue = queue
    }
    
    public func read<T>(_ block: () -> T?) -> T? {
        var result: T?
        queue.sync {
            result = block()
        }
        return result
    }
    
    public func write(_ block: @escaping () -> Void) {
        queue.async(flags: .barrier) {
            block()
        }
    }
}

