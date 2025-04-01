//
//  RecursiveReadWriteLock.swift
//  CacheManager
//
//  Created by Fan Zhou on 2025/4/1.
//

import Foundation

// swiftlint:disable empty_count
public class RecursiveReadWriteLock {
    private var rwLock = pthread_rwlock_t()
    private var threadReadCounts = [pthread_t: Int]()
    private var threadWriteCounts = [pthread_t: Int]()
    private let lock = NSLock() // Used to protect threadReadCounts and threadWriteCounts
    
    public init() {
        pthread_rwlock_init(&rwLock, nil)
    }
    
    deinit {
        pthread_rwlock_destroy(&rwLock)
    }
    
    // Acquire read lock
    public func readLock() {
        let thread = pthread_self()
        
        lock.lock()
        if let count = threadReadCounts[thread], count > 0 {
            // If the current thread already holds the read lock, allow recursive acquisition
            threadReadCounts[thread] = count + 1
            lock.unlock()
            return
        }
        lock.unlock()
        
        // Acquire read lock
        pthread_rwlock_rdlock(&rwLock)
        
        lock.lock()
        threadReadCounts[thread] = 1
        lock.unlock()
    }
    
    // Release read lock
    public func readUnlock() {
        let thread = pthread_self()
        
        lock.lock()
        guard let count = threadReadCounts[thread], count > 0 else {
            lock.unlock()
            fatalError("Attempted to release a read lock that was not held")
        }
        
        if count == 1 {
            // If this is the last recursive call, release the read lock
            threadReadCounts[thread] = nil
            lock.unlock()
            pthread_rwlock_unlock(&rwLock)
        } else {
            // Decrease the recursion count
            threadReadCounts[thread] = count - 1
            lock.unlock()
        }
    }
    
    // Acquire write lock
    public func writeLock() {
        let thread = pthread_self()
        
        lock.lock()
        if let count = threadWriteCounts[thread], count > 0 {
            // If the current thread already holds the write lock, allow recursive acquisition
            threadWriteCounts[thread] = count + 1
            lock.unlock()
            return
        }
        lock.unlock()
        
        // Acquire write lock
        pthread_rwlock_wrlock(&rwLock)
        
        lock.lock()
        threadWriteCounts[thread] = 1
        lock.unlock()
    }
    
    // Release write lock
    public func writeUnlock() {
        let thread = pthread_self()
        
        lock.lock()
        guard let count = threadWriteCounts[thread], count > 0 else {
            lock.unlock()
            fatalError("Attempted to release a write lock that was not held")
        }
        
        if count == 1 {
            // If this is the last recursive call, release the write lock
            threadWriteCounts[thread] = nil
            lock.unlock()
            pthread_rwlock_unlock(&rwLock)
        } else {
            // Decrease the recursion count
            threadWriteCounts[thread] = count - 1
            lock.unlock()
        }
    }
}

extension RecursiveReadWriteLock: ReadWriteLockProtocol {
    public func read<T>(_ block: () -> T?) -> T? {
        readLock()
        defer {
            readUnlock()
        }
        return block()
    }
    
    public func write(_ block: @escaping () -> Void) {
        writeLock()
        defer {
            writeUnlock()
        }
        block()
    }
}

// swiftlint:enable empty_count
