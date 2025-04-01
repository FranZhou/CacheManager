//
//  DiskCacheManagerTests.swift
//  CacheManager
//
//  Created by Fan Zhou on 2025/4/1.
//

import XCTest

@testable import CacheManager

class DiskCacheManagerTests: XCTestCase {
    var diskFileManagerMock: DiskFileManagerMock!
    var timeProviderMock: TimeProviderMock!
    var configurationMock: DiskCacheConfiguration!
    var readWriteLockMock: ReadWriteLockProtocol!
    
    override func setUp() {
        super.setUp()
        diskFileManagerMock = DiskFileManagerMock()
        timeProviderMock = TimeProviderMock(currentTime: Date())
        configurationMock = DiskCacheConfiguration(
            cleanupInterval: nil,
            cacheDirectory: URL(fileURLWithPath: "MOCK_CACHE"),
            expirationPolicy: .sinceLastAccess(1)
        )
        readWriteLockMock = GCDReadWriteLock(queue: .init(label: "DiskCacheManagerTestQueue"))
    }
    
    override func tearDown() {
        diskFileManagerMock = nil
        timeProviderMock = nil
        configurationMock = nil
        readWriteLockMock = nil
        super.tearDown()
    }
    
    private func buildSUT() -> DiskCacheManager<String, String> {
        DiskCacheManager<String, String>(
            configuration: configurationMock,
            fileManager: diskFileManagerMock,
            timeProvider: timeProviderMock,
            readWriteLock: readWriteLockMock
        )
    }
}

extension DiskCacheManagerTests {
    func test_GivenDiskCacheWithExpirationPolicySinceCreation_WhenItemExpires_ThenItemIsRemoved() {
        // Given
        configurationMock = DiskCacheConfiguration(
            cleanupInterval: nil,
            cacheDirectory: URL(fileURLWithPath: "MOCK_CACHE"),
            expirationPolicy: .sinceCreation(1)
        )
        let sut = buildSUT()
        sut.setValue("Value1", forKey: "key1")
        
        // When
        timeProviderMock.advance(by: 2)
        
        // Then
        XCTAssertNil(sut.value(forKey: "key1"))
    }
    
    func test_GivenDiskCacheWithExpirationPolicySinceLastAccess_WhenItemExpires_ThenItemIsRemoved() {
        // Given
        let sut = buildSUT()
        sut.setValue("Value1", forKey: "key1")
        
        // When
        timeProviderMock.advance(by: 2)
        
        // Then
        XCTAssertNil(sut.value(forKey: "key1"))
    }
    
    func test_GivenDiskCacheWithItems_WhenRemoveValueForKey_ThenItemIsRemoved() {
        // Given
        let sut = buildSUT()
        sut.setValue("Value1", forKey: "key1")
        
        // When
        sut.removeValue(forKey: "key1")
        
        // Then
        XCTAssertNil(sut.value(forKey: "key1"))
    }
    
    func test_GivenDiskCacheWithItems_WhenRemoveAll_ThenAllItemsAreRemoved() {
        // Given
        let sut = buildSUT()
        sut.setValue("Value1", forKey: "key1")
        sut.setValue("Value2", forKey: "key2")
        
        // When
        sut.removeAll()
        
        // Then
        XCTAssertNil(sut.value(forKey: "key1"))
        XCTAssertNil(sut.value(forKey: "key2"))
    }
    
    func test_GivenMemoryCacheWithExpirationPolicySinceLastAccess_WhenRemoveOverdueValues_ThenItemIsRemoved() {
        // Given
        let sut = buildSUT()
        sut.setValue("Value1", forKey: "key1")
        
        // When
        timeProviderMock.advance(by: 2)
        sut.removeOverdueValues()
        
        // Then
        XCTAssertNil(sut.value(forKey: "key1"))
    }
    
    func test_GivenDiskCacheWithConcurrentAccess_WhenReadingAndWriting_ThenNoDataRaces() {
        // Given
        let capacity = 10
        let sut = buildSUT()
        let dispatchGroup = DispatchGroup()
        
        // When
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
            XCTAssertEqual(sut.value(forKey: "key\(i)"), "Value\(i)")
        }
    }
}
