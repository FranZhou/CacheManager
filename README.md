# CacheManager

CacheManager is a robust, flexible, and efficient caching solution for Swift applications. It provides a multi-level caching system with support for both memory and disk caching, making it suitable for a wide range of use cases in iOS, macOS, tvOS, and watchOS applications.

## Features

- Multi-level caching (memory and disk)
- Flexible expiration policies
- Thread-safe operations
- Customizable cache configurations
- LRU (Least Recently Used) algorithm for memory cache
- Efficient disk caching with automatic cleanup
- Easy-to-use API

## Components

### CacheManagerProtocol

The `CacheManagerProtocol` defines the core functionality for all cache managers in the system. It includes methods for setting, retrieving, and removing values, as well as clearing the entire cache and removing overdue values.

### MultiLevelCacheManager

`MultiLevelCacheManager` combines multiple cache layers (e.g., memory and disk) to provide optimal performance and persistence. It manages the synchronization between different cache levels and ensures data consistency.

### MemoryCacheManager

`MemoryCacheManager` implements an in-memory cache using an LRU (Least Recently Used) algorithm. It provides fast access to frequently used data while automatically managing memory usage.

### DiskCacheManager

`DiskCacheManager` provides persistent storage of cache items on disk. It handles file operations, data serialization/deserialization, and automatic cleanup of expired items.

## Usage

Here's a basic example of how to use CacheManager:

```swift
// Create readWrite lock
let readWriteLock = RecursiveReadWriteLock()

// Create configurations
let memoryCacheConfig = MemoryCacheConfiguration(
        cleanupInterval: nil,
        capacity: 14,
        expirationPolicy: .sinceLastAccess(TimeInterval(30 * 24 * 60 * 60))
    )
let diskCacheConfig = DiskCacheConfiguration(
        cleanupInterval: nil,
        cacheDirectory: {
            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let directory = path.appendingPathComponent("\(TrackYourDreamCNModule.logContext)/\("cacheManagerDemo")")
            return directory
        }(),
        expirationPolicy: .sinceLastAccess(TimeInterval(30 * 24 * 60 * 60))
    )

// Create individual cache managers
let memoryCache = MemoryCacheManager<String, Data>(configuration: memoryCacheConfig, readWriteLock: readWriteLock)
let diskCache = DiskCacheManager<String, Data>(configuration: diskCacheConfig, readWriteLock: readWriteLock)

// Create a multi-level cache manager
let cacheManager = MultiLevelCacheManager(cacheManagers: [memoryCache, diskCache], readWriteLock: readWriteLock)

// Use the cache manager
cacheManager.setValue(myData, forKey: "myKey")
if let cachedData = cacheManager.value(forKey: "myKey") {
    // Use the cached data
}
cacheManager.removeValue(forKey: "myKey")
cacheManager.removeAll()
```

## Thread Safety

CacheManager uses a custom implementation of read-write locks to ensure thread-safe operations across all cache levels. This allows for concurrent read access while ensuring exclusive write access when needed.

## Installation

You can add CacheManager to your project using Swift Package Manager. Add the following line to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/CacheManager.git", from: "1.0.0")
]
```

## Requirements

- Swift 5.0+
- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+

## License

CacheManager is available under the MIT license. See the LICENSE file for more info.

## Author

Created by Fan Zhou.

## Contributing

Contributions to CacheManager are welcome! Please feel free to submit a Pull Request.

## Acknowledgements

This project was inspired by various caching solutions in the iOS development community and aims to provide a comprehensive and flexible caching system for Swift applications.