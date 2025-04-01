//
//  LRUCache.swift
//  CacheManager
//
//  Created by Fan Zhou on 2025/4/1.
//

import Foundation

public class LRUCache<Key: Hashable, Value> {
    private let capacity: Int
    
    private var cache: [Key: Node]
    
    private let queue: DispatchQueue
    
    private var head: Node?
    
    private var tail: Node?
    
    public init(capacity: Int, queue: DispatchQueue = DispatchQueue(label: "LRUCache.queue", attributes: .concurrent)) {
        self.capacity = max(0, capacity)
        self.cache = [:]
        self.queue = queue
    }
    
    public func setValue(_ value: Value, forKey key: Key) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else {
                return
            }
            if let node = self.cache[key] {
                // Update the value and move it to the head of the node list.
                node.value = value
                self.moveToHead(node)
            } else {
                // Create a new node and add it to the head of the node list.
                let newNode = Node(key: key, value: value)
                self.cache[key] = newNode
                self.addToHead(newNode)
                
                // If the capacity is exceeded, remove the node at the tail of the node list.
                if self.cache.count > self.capacity, let tailNode = self.tail {
                    self.cache.removeValue(forKey: tailNode.key)
                    self.removeNode(tailNode)
                }
            }
        }
    }
    
    public func value(forKey key: Key) -> Value? {
        var result: Value?
        queue.sync { [weak self] in
            guard let self,
                  let node = self.cache[key] else {
                return
            }
            // Move node to the head of the node list.
            moveToHead(node)
            result = node.value
        }
        return result
    }
    
    public func removeValue(forKey key: Key) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self,
                  let node = self.cache[key] else {
                return
            }
            removeNode(node)
            cache.removeValue(forKey: key)
        }
    }
    
    public func removeAll() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else {
                return
            }
            cache.removeAll()
            head = nil
            tail = nil
        }
    }
    
    public var count: Int {
        var result = 0
        queue.sync { [weak self] in
            guard let self else {
                return
            }
            result = cache.count
        }
        return result
    }
    
    public var keys: [Key] {
        var result: [Key] = []
        queue.sync { [weak self] in
            guard let self else {
                return
            }
            result = Array(cache.keys)
        }
        return result
    }
}

// MARK: - Operations of node list
private extension LRUCache {
    func addToHead(_ node: Node) {
        node.prev = nil
        node.next = head
        head?.prev = node
        head = node
        
        if tail == nil {
            tail = node
        }
    }
    
    func removeNode(_ node: Node) {
        node.prev?.next = node.next
        node.next?.prev = node.prev
        
        if node === head {
            head = node.next
        }
        if node === tail {
            tail = node.prev
        }
    }
    
    func moveToHead(_ node: Node) {
        guard node !== head else { return }
        removeNode(node)
        addToHead(node)
    }
}

private extension LRUCache {
    class Node {
        let key: Key
        var value: Value
        var prev: Node?
        var next: Node?
        
        init(key: Key, value: Value) {
            self.key = key
            self.value = value
        }
    }
}
