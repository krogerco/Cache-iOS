# Cache for iOS

The Cache library provides easy to use key/value caches, with configurable caching policies and optional persistence.

This first version of Cache provides an in-memory key/value cache with persistence. Future versions will include more comprehensive caching systems. 

## Requirements

- Xcode 14.0+
- Swift 5.7+

## Installation

The easiest way to install Cache is by adding a dependency via SPM.

```swift
    .package(
        url: "https://github.com/krogerco/Cache-iOS.git",
        from: Version(1, 0, 0)
    )
```

## Quick Start

Getting a basic memory cache with persistence is easy:

```swift
    // The type to be cached. This only needs to conform to ``Codable``.
    struct Customer: Codable {
        let id: String
        let name: String
        let address: String
    }

    // Define the policies to be used for items in the cache.
    // Here we have both a max item count and a max item lifetime, but you can use either or both.
    let policies: [CachePolicy] = [.maxItemCount(42), .maxItemLifetime(60.0)]

    // Setup the cache. By default, caches are stored in the OS cache directory and
    // the identifier is used as part of the directory name where the cache is stored.
    let cache = Cache<String, Customer>(policies: policies, identifier: "CustomerCache")

    // Sample data.
    let customer = Customer(id: UUID().uuidString, name: "Jane", address: "123 Swift Street")

    // Set a value.
    cache[customer.id] = customer

    // Get a value.
    let retrievedCustomer = cache[customer.id]
```

## Documentation

Cache has full DocC documentation. After adding to your project, `Build Documentation` to add to your documentation viewer.

### Online Documentation

[Getting Started](Sources/Telemetry/Documentation.docc/GettingStarted.md)
[Full Documentation](https://krogerco.github.io/Cache-iOS.git/documentation/cache)


## Communication

If you have issues or suggestions, please open an issue on GitHub.
