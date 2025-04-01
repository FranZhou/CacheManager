//
//  TimeProviderMock.swift
//  CacheManager
//
//  Created by Fan Zhou on 2025/4/1.
//

import Foundation

import CacheManager

class TimeProviderMock: TimeProviderProtocol {
    var currentTime: Date
    init(currentTime: Date) {
        self.currentTime = currentTime
    }
    
    func advance(by timeInterval: TimeInterval) {
        currentTime = currentTime.addingTimeInterval(timeInterval)
    }
}
