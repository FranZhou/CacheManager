//
//  MultiLevelCacheManager.swift
//  CacheManager
//
//  Created by Fan Zhou on 2025/4/1.
//

import XCTest

@testable import CacheManager

class MultiLevelCacheManagerTests: XCTestCase {
    var diskFileManagerMock: DiskFileManagerMock!
    var diskTimeProviderMock: TimeProviderMock!
    var diskConfigurationMock: DiskCacheConfiguration!
    
    var memoryTimeProviderMock: TimeProviderMock!
    var memoryConfigurationMock: MemoryCacheConfiguration!
    
    var readWriteLockMock: ReadWriteLockProtocol!
    
    override func setUp() {
        super.setUp()
        
        diskFileManagerMock = DiskFileManagerMock()
        diskTimeProviderMock = TimeProviderMock(currentTime: Date())
        diskConfigurationMock = DiskCacheConfiguration(
            cleanupInterval: nil,
            cacheDirectory: URL(fileURLWithPath: "MOCK_CACHE"),
            expirationPolicy: .sinceLastAccess(1)
        )
        memoryTimeProviderMock = TimeProviderMock(currentTime: Date())
        memoryConfigurationMock = MemoryCacheConfiguration(
            capacity: 2,
            expirationPolicy: .sinceLastAccess(1)
        )
        
        readWriteLockMock = RecursiveReadWriteLock()
    }
    
    override func tearDown() {
        diskFileManagerMock = nil
        diskTimeProviderMock = nil
        diskConfigurationMock = nil
        memoryTimeProviderMock = nil
        memoryConfigurationMock = nil
        readWriteLockMock = nil
        super.tearDown()
    }
    
    private func buildMemoryCacheManager() -> MemoryCacheManager<String, String> {
        MemoryCacheManager<String, String>(
            configuration: memoryConfigurationMock,
            timeProvider: memoryTimeProviderMock,
            readWriteLock: readWriteLockMock
        )
    }
    
    private func buildDiskCacheManager() -> DiskCacheManager<String, String> {
        DiskCacheManager<String, String>(
            configuration: diskConfigurationMock,
            fileManager: diskFileManagerMock,
            timeProvider: diskTimeProviderMock,
            readWriteLock: readWriteLockMock
        )
    }
    
    private func buildSUT(cacheManagers: [any CacheManagerProtocol<String, String>]) -> (MultiLevelCacheManager<String, String>) {
        MultiLevelCacheManager<String, String>(cacheManagers: cacheManagers, readWriteLock: readWriteLockMock)
    }
}

extension MultiLevelCacheManagerTests {
    func test_GivenMultiLevelCacheAndValueCachedInMemory_WhenValueForKey_ThenItemIsFetchedFromMemoryCache() {
        // Given
        let memoryCacheManager = buildMemoryCacheManager()
        let diskCacheManager = buildDiskCacheManager()
        let sut = buildSUT(cacheManagers: [memoryCacheManager, diskCacheManager])
        
        // When
        memoryCacheManager.setValue("Value1", forKey: "key1")
        diskCacheManager.removeAll()
        
        // Then
        XCTAssertEqual(sut.value(forKey: "key1"), "Value1")
        XCTAssertNil(diskCacheManager.value(forKey: "key1"))
    }
    
    func test_GivenMultiLevelCacheAndValueCachedInDisk_WhenValueForKey_ThenItemIsFetchedFromDiskCache() {
        // Given
        let memoryCacheManager = buildMemoryCacheManager()
        let diskCacheManager = buildDiskCacheManager()
        let sut = buildSUT(cacheManagers: [memoryCacheManager, diskCacheManager])
        
        // When
        memoryCacheManager.removeAll()
        diskCacheManager.setValue("Value1", forKey: "key1")
        
        // Then
        XCTAssertNil(memoryCacheManager.value(forKey: "key1"))
        XCTAssertEqual(sut.value(forKey: "key1"), "Value1")
    }
    
    func test_GivenMultiLevelCacheAndCachedValue_WhenRemoveValueForKey_ThenItemIsRemovedFromAllCaches() {
        // Given
        let memoryCacheManager = buildMemoryCacheManager()
        let diskCacheManager = buildDiskCacheManager()
        let sut = buildSUT(cacheManagers: [memoryCacheManager, diskCacheManager])
        
        sut.setValue("Value1", forKey: "key1")
        
        // When
        sut.removeValue(forKey: "key1")
        
        // Then
        XCTAssertNil(sut.value(forKey: "key1"))
    }
    
    func test_GivenMultiLevelCacheAndCachedValueInMemoryAndDisk_WhenRemoveAll_ThenItemIsRemovedFromAllCaches() {
        // Given
        let memoryCacheManager = buildMemoryCacheManager()
        let diskCacheManager = buildDiskCacheManager()
        let sut = buildSUT(cacheManagers: [memoryCacheManager, diskCacheManager])
        
        memoryCacheManager.setValue("Value1", forKey: "key1")
        diskCacheManager.setValue("Value2", forKey: "key2")
        
        // When
        sut.removeAll()
        
        // Then
        XCTAssertNil(sut.value(forKey: "key1"))
        XCTAssertNil(sut.value(forKey: "key2"))
    }
    
    func test_GivenMultiLevelCacheAndCachedValueInMemoryAndDisk_WhenRemoveOverdueValues_ThenItemIsRemovedFromAllCaches() {
        // Given
        let memoryCacheManager = buildMemoryCacheManager()
        let diskCacheManager = buildDiskCacheManager()
        let sut = buildSUT(cacheManagers: [memoryCacheManager, diskCacheManager])
        
        memoryCacheManager.setValue("Value1", forKey: "key1")
        memoryTimeProviderMock.advance(by: 2)
        
        diskCacheManager.setValue("Value2", forKey: "key2")
        diskTimeProviderMock.advance(by: 2)
        
        // When
        sut.removeOverdueValues()
        
        // Then
        XCTAssertNil(sut.value(forKey: "key1"))
        XCTAssertNil(sut.value(forKey: "key2"))
    }
    
    func test_GivenMultiLevelCacheAndCachedValueInMemoryAndDiskAndNeverExpires_WhenRemoveOverdueValues_ThenItemIsNotRemovedFromCaches() {
        // Given
        memoryConfigurationMock = MemoryCacheConfiguration(
            capacity: 2,
            expirationPolicy: .never
        )
        let memoryCacheManager = buildMemoryCacheManager()
        
        diskConfigurationMock = DiskCacheConfiguration(
            cleanupInterval: nil,
            cacheDirectory: URL(fileURLWithPath: "MOCK_CACHE"),
            expirationPolicy: .never
        )
        let diskCacheManager = buildDiskCacheManager()
        
        let sut = buildSUT(cacheManagers: [memoryCacheManager, diskCacheManager])
        
        memoryCacheManager.setValue("Value1", forKey: "key1")
        memoryTimeProviderMock.advance(by: 999)
        
        diskCacheManager.setValue("Value2", forKey: "key2")
        diskTimeProviderMock.advance(by: 999)
        
        // When
        sut.removeOverdueValues()
        
        // Then
        XCTAssertEqual(sut.value(forKey: "key1"), "Value1")
        XCTAssertEqual(sut.value(forKey: "key2"), "Value2")
    }
    
    func test_GivenMultiLevelCacheWithConcurrentAccess_WhenReadingAndWriting_ThenNoDataRaces() {
        // Given
        let capacity = 10
        
        memoryConfigurationMock = MemoryCacheConfiguration(
            capacity: capacity,
            expirationPolicy: .sinceLastAccess(1)
        )
        
        let memoryCacheManager = buildMemoryCacheManager()
        let diskCacheManager = buildDiskCacheManager()
        let sut = buildSUT(cacheManagers: [memoryCacheManager, diskCacheManager])
        
        // When
        let dispatchGroup = DispatchGroup()
        for i in 0 ..< capacity {
            dispatchGroup.enter()
            DispatchQueue.global().async {
                sut.setValue("Value\(i)", forKey: "key\(i)")
                dispatchGroup.leave()
            }
        }
        dispatchGroup.wait()
        
        // Then
        for i in 0 ..< capacity {
            XCTAssertEqual(memoryCacheManager.value(forKey: "key\(i)"), "Value\(i)")
            XCTAssertEqual(diskCacheManager.value(forKey: "key\(i)"), "Value\(i)")
            XCTAssertEqual(sut.value(forKey: "key\(i)"), "Value\(i)")
        }
    }
}
