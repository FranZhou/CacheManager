//
//  ReadWriteLockProtocol.swift
//  CacheManager
//
//  Created by Fan Zhou on 2025/4/1.
//

public protocol ReadWriteLockProtocol {
    func read<T>(_ block: () -> T?) -> T?
    func write(_ block: @escaping () -> Void)
}

public class UnsafeReadWriteLock: ReadWriteLockProtocol {
    public init() {}
    
    public func read<T>(_ block: () -> T?) -> T? {
        block()
    }
    
    public func write(_ block: @escaping () -> Void) {
        block()
    }
}
