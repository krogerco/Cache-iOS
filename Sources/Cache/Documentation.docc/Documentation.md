# ``Cache``

The Cache library provides easy to use key/value caches, with configurable caching policies and optional persistence.

``Cache`` implements an in-memory key/value cache that supports configurable retention policies and on-disk persistence across uses.

## Setup

Setting up a ``Cache`` is easy. The ``Cache`` type is generic on the key and value types.

The key type needs to conform to `Comparable`, `Hashable` and `Codable`.

The value type only needs to conform to `Codable`.

### Policies

Policies control the size of the cache and lifetime of items in the cache.

- ``CachePolicy/maxItemCount(_:)`` policy sets the maximum number of items allowed in the cache. Once the maximum number of items is hit, older items are evicted to make room for new items.
- ``CachePolicy/maxItemLifetime(_:)`` policy governs the length of time any given item will stay in the cache. Items who have been in the cache longer than this value will be evicted.

A ``Cache`` defaults to policies of:

- Maximum of 1000 items in memory.
- Each item has a maximum lifetime of 1 hour.

You can also pass in a customized set of policies that suits your particular needs.

> Note: It is possible to pass in an empty policy list, which will result in a cache with no size or lifetime limits.

### Persistence

Caches can optionally be persisted to disk by specifying a ``CacheLocation``, which describes where the caches files will be saved.

``CacheLocation`` takes a location name and (optionally) a parent URL. The name will become part of the directory name that contains the files for the cache. It should be unique for every separate cache instance you create.

By default, a ``CacheLocation`` is located inside of the `FileManager`s Cache directory. However, you can pass in a custom parent URL where the cache directory will be located. 

## Example

```swift
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


## Topics

### Cache Configuration

- ``CacheLocation``
- ``CacheDelegate``
- ``CacheConfig``

### Policies

- ``CachePolicy``

### MemoryCache

- ``MemoryCache``
