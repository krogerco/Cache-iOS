// MIT License
//
// Copyright (c) 2023 The Kroger Co. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Combine
import Foundation

typealias EventPublisher = PassthroughSubject<CacheEvent, Never>

/// A memory based cache with configurable policies and optional persistence.
public final class Cache<Key: CacheKey, Value: Codable> {
    let lock = NSRecursiveLock()
    let layer: MemoryCacheLayer<Key, Value>
    let identifier: String

    /// Publishes interesting events during the cache lifecycle. Can be useful for debugging.
    public var events: AnyPublisher<CacheEvent, Never> { eventPublisher.eraseToAnyPublisher() }

    let eventPublisher = EventPublisher()

    /// Create a ``Cache``.
    /// - Parameters:
    ///   - policies:   Policies to use for this cache. Defaults to 1000 items with a 1 hour lifetime.
    ///   - identifier: Identifier for this cache. This will be part of the filename if persisted,
    ///                 so this should be unique per use-case.
    ///   - delegate:   Optional delegate for logging.
    ///   - location:   If passed, this will be the directory the cache files are stored in.
    public init(
        policies: [CachePolicy] = [.maxItemCount(1000), .maxItemLifetime(3600)],
        identifier: String,
        location: CacheLocation? = nil
    ) {
        self.layer = MemoryCacheLayer(policies: policies)
        self.identifier = identifier

        // Setup
        let config = CacheConfig(location: location, eventPublisher: eventPublisher)
        layer.setup(config: config)
    }

    /// Get values (if they exist) for the passed keys.
    /// - Parameter keys: Keys to search for.
    ///
    /// - Returns: Dictionary of key/value pairs for any keys that exist in the cache.
    public func values(for keys: Set<Key>) -> [Key: Value] {
        lock.lock(); defer { lock.unlock() }

        // Purge expired items from the cache so we are working with current data.
        layer.applyTemporalPolicies()

        let accessDate = Date()
        let items = layer.items(for: keys, accessDate: accessDate)
        let keysAndValues = items.map { ($0.key, $0.value) }
        let dictionary = Dictionary(uniqueKeysWithValues: keysAndValues)

        return dictionary
    }

    /// Get a value (if any) for a key.
    /// - Parameter key: Key to search for.
    ///
    /// - Returns: Value or `nil`.
    public func value(for key: Key) -> Value? {
        values(for: [key])[key]
    }

    /// Subscript operator to get and set values in the cache.
    /// - Parameter key: Key to search for.
    ///
    /// - Returns: Value or `nil`.
    public subscript(key: Key) -> Value? {
        get {
            value(for: key)
        }
        set(value) {
            if let value {
                set(value: value, for: key)
            } else {
                removeValues(for: Set([key]))
            }
        }
    }

    /// Set the value for a key.
    /// - Parameters:
    ///   - value:  Value to set.
    ///   - key:    Key to receive the value
    public func set(value: Value, for key: Key) {
        lock.lock(); defer { lock.unlock() }

        let date = Date()
        layer.set([CacheItem(key: key, creationDate: date, lastAccessDate: date, value: value)])

        layer.applyTemporalPolicies()
        layer.applySizePolicies()
    }

    /// Bulk set values for keys with a dictionary.
    /// - Parameter dictionary: Dictionary of keys and values to set.
    public func set(_ dictionary: [Key: Value]) {
        lock.lock(); defer { lock.unlock() }

        let date = Date()
        let items = dictionary.map { CacheItem(key: $0, creationDate: date, lastAccessDate: date, value: $1) }
        layer.set(items)

        layer.applyTemporalPolicies()
        layer.applySizePolicies()
    }

    /// Remove the current values (if any) for the passed keys.
    /// - Parameter keys: Keys for which values should be removed.
    public func removeValues(for keys: Set<Key>) {
        lock.lock(); defer { lock.unlock() }

        layer.removeValues(for: keys)
        layer.applyTemporalPolicies()
    }

    /// Remove all values from the cache.
    public func removeAll() {
        lock.lock(); defer { lock.unlock() }

        layer.removeAll()
    }
}
