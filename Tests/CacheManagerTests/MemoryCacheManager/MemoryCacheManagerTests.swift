//
//  MemoryCacheManagerTests.swift
//  CacheManager
//
//  Created by Fan Zhou on 2025/4/1.
//

import XCTest

@testable import CacheManager

class MemoryCacheManagerTests: XCTestCase {
    var timeProviderMock: TimeProviderMock!
    var configurationMock: MemoryCacheConfiguration!
    var readWriteLockMock: ReadWriteLockProtocol!
    
    override func setUp() {
        super.setUp()
        timeProviderMock = TimeProviderMock(currentTime: Date())
        configurationMock = MemoryCacheConfiguration(
            capacity: 2,
            expirationPolicy: .sinceLastAccess(1)
        )
        readWriteLockMock = GCDReadWriteLock(queue: .init(label: "MemoryCacheManagerTestQueue"))
    }
    
    override func tearDown() {
        timeProviderMock = nil
        configurationMock = nil
        readWriteLockMock = nil
        super.tearDown()
    }
    
    private func buildSUT() -> MemoryCacheManager<String, String> {
        MemoryCacheManager<String, String>(
            configuration: configurationMock,
            timeProvider: timeProviderMock,
            readWriteLock: readWriteLockMock
        )
    }
}

extension MemoryCacheManagerTests {
    func test_GivenMemoryCacheWithCapacity2_WhenAddingThreeItems_ThenFirstItemIsEvicted() {
        // Given
        let sut = buildSUT()
        sut.setValue("Value1", forKey: "key1")
        sut.setValue("Value2", forKey: "key2")
        
        // When
        sut.setValue("Value3", forKey: "key3")
        
        // Then
        XCTAssertNil(sut.value(forKey: "key1"))
        XCTAssertEqual(sut.value(forKey: "key2"), "Value2")
        XCTAssertEqual(sut.value(forKey: "key3"), "Value3")
    }
    
    func test_GivenMemoryCacheWithExpirationPolicySinceLastAccess_WhenItemExpires_ThenItemIsRemoved() {
        // Given
        let sut = buildSUT()
        sut.setValue("Value1", forKey: "key1")
        
        // When
        timeProviderMock.advance(by: 2)
        
        // Then
        XCTAssertNil(sut.value(forKey: "key1"))
    }
    
    func test_GivenMemoryCacheWithExpirationPolicySinceCreation_WhenItemExpires_ThenItemIsRemoved() {
        // Given
        configurationMock = MemoryCacheConfiguration(
            capacity: 2,
            expirationPolicy: .sinceCreation(1)
        )
        let sut = buildSUT()
        sut.setValue("Value1", forKey: "key1")
        
        // When
        timeProviderMock.advance(by: 2)
        
        // Then
        XCTAssertNil(sut.value(forKey: "key1"))
    }
    
    func test_GivenMemoryCacheWithItems_WhenRemoveValueForKey_ThenItemIsRemoved() {
        // Given
        let sut = buildSUT()
        sut.setValue("Value1", forKey: "key1")
        
        // When
        sut.removeValue(forKey: "key1")
        
        // Then
        XCTAssertNil(sut.value(forKey: "key1"))
    }
    
    func test_GivenMemoryCacheWithItems_WhenRemoveAll_ThenAllItemsAreRemoved() {
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
    
    func test_GivenMemoryCacheWithConcurrentAccess_WhenReadingAndWriting_ThenNoDataRaces() {
        // Given
        let capacity = 10
        configurationMock = MemoryCacheConfiguration(
            capacity: capacity,
            expirationPolicy: .sinceCreation(1)
        )
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
