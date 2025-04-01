//
//  MemoryCacheManager.swift
//  CacheManager
//
//  Created by Fan Zhou on 2025/4/1.
//

import Foundation

public class MemoryCacheManager<Key: Hashable, Value>: CacheManagerProtocol {
    private let timerQueue: DispatchQueue
    private var cleanupTimer: DispatchSourceTimer?
    private let readWriteLock: any ReadWriteLockProtocol
    
    private let lruCache: LRUCache<Key, CacheItem<Value>>
    private let configuration: MemoryCacheConfiguration
    private let timeProvider: TimeProviderProtocol
    
    public init(configuration: MemoryCacheConfiguration,
                timerQueue: DispatchQueue = DispatchQueue(label: "DiskCacheManager.TimerQueue"),
                timeProvider: any TimeProviderProtocol = TimeProvider(),
                readWriteLock: any ReadWriteLockProtocol) {
        self.configuration = configuration
        self.timerQueue = timerQueue
        self.timeProvider = timeProvider
        self.lruCache = LRUCache<Key, CacheItem<Value>>(capacity: configuration.capacity)
        self.readWriteLock = readWriteLock
        
        startCleanupTimer()
    }
    
    deinit {
        cleanupTimer?.cancel()
    }
    
    public func setValue(_ value: Value, forKey key: Key) {
        let cacheItem = CacheItem(value: value, expirationPolicy: configuration.expirationPolicy, currentTime: timeProvider.currentTime)
        readWriteLock.write { [weak self] in
            guard let self else {
                return
            }
            lruCache.setValue(cacheItem, forKey: key)
        }
    }
    
    public func value(forKey key: Key) -> Value? {
        readWriteLock.read { [weak self] in
            guard let self,
                  var cacheItem = lruCache.value(forKey: key) else {
                return nil
            }
            var result: Value?
            if cacheItem.isExpired(currentTime: timeProvider.currentTime) {
                lruCache.removeValue(forKey: key)
            } else {
                cacheItem.updateLastAccessTime(currentTime: timeProvider.currentTime)
                lruCache.setValue(cacheItem, forKey: key)
                result = cacheItem.value
            }
            return result
        }
    }
    
    public func removeValue(forKey key: Key) {
        readWriteLock.write { [weak self] in
            guard let self else {
                return
            }
            lruCache.removeValue(forKey: key)
        }
    }
    
    public func removeAll() {
        readWriteLock.write { [weak self] in
            guard let self else {
                return
            }
            lruCache.removeAll()
        }
    }
    
    public func removeOverdueValues() {
        readWriteLock.write { [weak self] in
            guard let self else {
                return
            }
            for key in lruCache.keys {
                guard let value = lruCache.value(forKey: key),
                      value.isExpired(currentTime: timeProvider.currentTime) else {
                    continue
                }
                lruCache.removeValue(forKey: key)
            }
        }
    }
}

private extension MemoryCacheManager {
    func startCleanupTimer() {
        guard let cleanupInterval = configuration.cleanupInterval,
              cleanupInterval > 0 else {
            removeOverdueValues()
            return
        }
        cleanupTimer = DispatchSource.makeTimerSource(queue: timerQueue)
        cleanupTimer?.schedule(deadline: .now(), repeating: cleanupInterval)
        cleanupTimer?.setEventHandler { [weak self] in
            self?.removeOverdueValues()
        }
        cleanupTimer?.resume()
    }
}
