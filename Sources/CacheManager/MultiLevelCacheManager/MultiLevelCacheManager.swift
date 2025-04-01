//
//  MultiLevelCacheManager.swift
//  CacheManager
//
//  Created by Fan Zhou on 2025/4/1.
//

import Foundation

public class MultiLevelCacheManager<Key: Hashable, Value>: CacheManagerProtocol {
    private let cacheManagers: [any CacheManagerProtocol<Key, Value>]
    private let readWriteLock: any ReadWriteLockProtocol
    
    public init(cacheManagers: [any CacheManagerProtocol<Key, Value>], readWriteLock: any ReadWriteLockProtocol) {
        self.cacheManagers = cacheManagers
        self.readWriteLock = readWriteLock
    }
    
    public func setValue(_ value: Value, forKey key: Key) {
        readWriteLock.write { [weak self] in
            guard let self else {
                return
            }
            for cacheManager in cacheManagers {
                cacheManager.setValue(value, forKey: key)
            }
        }
    }
    
    public func value(forKey key: Key) -> Value? {
        var writeIfNeeded: (() -> Void)?
        
        // read value from cache in readLock
        let result: Value? = readWriteLock.read { [weak self] in
            guard let self else {
                return nil
            }
            for cacheManager in cacheManagers {
                if let value = cacheManager.value(forKey: key) {
                    // If you try to acquire a write lock while holding a read lock, it will lead to a deadlock.
                    // So sync value to high level cahce mamager after readUnlock
                    writeIfNeeded = { [weak self] in
                        guard let self else {
                            return
                        }
                        updateHigherPriorityCaches(value: value, forKey: key, startingFrom: cacheManager)
                    }
                    return value
                }
            }
            return nil
        }
        
        // start write
        writeIfNeeded?()
        
        return result
    }
    
    public func removeValue(forKey key: Key) {
        readWriteLock.write { [weak self] in
            guard let self else {
                return
            }
            for cacheManager in cacheManagers {
                cacheManager.removeValue(forKey: key)
            }
        }
    }
    
    public func removeAll() {
        readWriteLock.write { [weak self] in
            guard let self else {
                return
            }
            for cacheManager in cacheManagers {
                cacheManager.removeAll()
            }
        }
    }
    
    public func removeOverdueValues() {
        readWriteLock.write { [weak self] in
            guard let self else {
                return
            }
            for cacheManager in cacheManagers {
                cacheManager.removeOverdueValues()
            }
        }
    }
}

private extension MultiLevelCacheManager {
    func updateHigherPriorityCaches(value: Value, forKey key: Key, startingFrom cacheManager: any CacheManagerProtocol<Key, Value>) {
        readWriteLock.write { [weak self] in
            guard let self else {
                return
            }
            guard let index = cacheManagers.firstIndex(where: { $0 === cacheManager }) else {
                return
            }
            for cacheIndex in (0 ..< index).reversed() {
                cacheManagers[cacheIndex].setValue(value, forKey: key)
            }
        }
    }
}
