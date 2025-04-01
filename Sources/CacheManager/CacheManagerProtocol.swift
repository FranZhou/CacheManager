//
//  CacheManagerProtocol.swift
//  CacheManager
//
//  Created by Fan Zhou on 2025/4/1.
//

public protocol CacheManagerProtocol<Key, Value>: AnyObject {
    associatedtype Key: Hashable
    associatedtype Value
    
    func setValue(_ value: Value, forKey key: Key)
    
    func value(forKey key: Key) -> Value?
    
    func removeValue(forKey key: Key)
    
    func removeAll()
    
    func removeOverdueValues()
}
