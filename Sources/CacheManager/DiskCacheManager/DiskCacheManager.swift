//
//  DiskCacheManager.swift
//  CacheManager
//
//  Created by Fan Zhou on 2025/4/1.
//

import Foundation

public class DiskCacheManager<Key: Hashable, Value: Codable>: CacheManagerProtocol {
    private let timerQueue: DispatchQueue
    private var cleanupTimer: DispatchSourceTimer?
    private let readWriteLock: any ReadWriteLockProtocol
    
    private let configuration: DiskCacheConfiguration
    private let fileManager: DiskFileManagerProtocol
    private let timeProvider: TimeProviderProtocol
    
    public init(configuration: DiskCacheConfiguration,
                timerQueue: DispatchQueue = DispatchQueue(label: "DiskCacheManager.TimerQueue"),
                fileManager: any DiskFileManagerProtocol = DiskFileManager(),
                timeProvider: any TimeProviderProtocol = TimeProvider(),
                readWriteLock: any ReadWriteLockProtocol) {
        self.configuration = configuration
        self.timerQueue = timerQueue
        self.fileManager = fileManager
        self.timeProvider = timeProvider
        self.readWriteLock = readWriteLock
        
        createCacheDirectoryIfNeeded(inLock: false)
        startCleanupTimer()
    }
    
    deinit {
        cleanupTimer?.cancel()
    }
    
    public func setValue(_ value: Value, forKey key: Key) {
        let cacheItem = CacheItem(value: value, expirationPolicy: configuration.expirationPolicy, currentTime: timeProvider.currentTime)
        let fileURL = fileURL(forKey: key)
        readWriteLock.write { [weak self] in
            guard let self,
                  let data = try? JSONEncoder().encode(cacheItem) else {
                return
            }
            _ = fileManager.createFile(atPath: fileURL.path, contents: data, attributes: nil)
        }
    }
    
    public func value(forKey key: Key) -> Value? {
        let fileURL = fileURL(forKey: key)
        return readWriteLock.read { [weak self] in
            guard let self,
                  let data = self.fileManager.contents(atPath: fileURL.path),
                  var cacheItem = try? JSONDecoder().decode(CacheItem<Value>.self, from: data) else {
                return nil
            }
            var result: Value?
            if cacheItem.isExpired(currentTime: timeProvider.currentTime) {
                try? fileManager.removeItem(at: fileURL)
            } else {
                cacheItem.updateLastAccessTime(currentTime: timeProvider.currentTime)
                result = cacheItem.value
                if let data = try? JSONEncoder().encode(cacheItem) {
                    _ = fileManager.createFile(atPath: fileURL.path, contents: data, attributes: nil)
                }
            }
            return result
        }
    }
    
    public func removeValue(forKey key: Key) {
        let fileURL = fileURL(forKey: key)
        readWriteLock.write { [weak self] in
            guard let self else {
                return
            }
            try? fileManager.removeItem(at: fileURL)
        }
    }
    
    public func removeAll() {
        readWriteLock.write { [weak self] in
            guard let self else {
                return
            }
            try? fileManager.removeItem(at: configuration.cacheDirectory)
            createCacheDirectoryIfNeeded(inLock: true)
        }
    }
    
    public func removeOverdueValues() {
        readWriteLock.write { [weak self] in
            guard let self,
                  let files = try? self.fileManager.contentsOfDirectory(atPath: self.configuration.cacheDirectory.path) else {
                return
            }
            for file in files {
                let fileURL = configuration.cacheDirectory.appendingPathComponent(file)
                guard let data = fileManager.contents(atPath: fileURL.path) else {
                    continue
                }
                if let cacheItem = try? JSONDecoder().decode(CacheItem<Value>.self, from: data),
                   !cacheItem.isExpired(currentTime: timeProvider.currentTime) {
                    continue
                } else {
                    try? fileManager.removeItem(at: fileURL)
                }
            }
        }
    }
}

private extension DiskCacheManager {
    func createCacheDirectoryIfNeeded(inLock: Bool) {
        let createCacheDirectory: () -> Void = { [weak self] in
            guard let self,
                  !fileManager.fileExists(atPath: self.configuration.cacheDirectory.path) else {
                return
            }
            try? fileManager.createDirectory(at: configuration.cacheDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        if inLock {
            createCacheDirectory()
        } else {
            readWriteLock.write {
                createCacheDirectory()
            }
        }
    }
    
    func fileURL(forKey key: Key) -> URL {
        return configuration.cacheDirectory.appendingPathComponent("\(key)")
    }
    
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
