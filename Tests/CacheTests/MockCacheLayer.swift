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

@testable import Cache
import Foundation

extension CacheItem: @retroactive Equatable where Key == String, Value: Equatable {
    public static func == (lhs: CacheItem<Key, Value>, rhs: CacheItem<Key, Value>) -> Bool {
        lhs.key == rhs.key &&
            lhs.creationDate == rhs.creationDate &&
            lhs.lastAccessDate == rhs.lastAccessDate &&
            lhs.value == rhs.value
    }
}

enum MockCacheError: Error, Equatable {
    case mockError
}

class MockCacheLayer: CacheLayer {
    typealias Key = String
    typealias Value = MockCacheValue

    var cache: [String: MockCacheValue] = [:]
    var keysProcessed: [Key] = []
    var keysSet: [Key] = []
    var delay: TimeInterval = 0.0

    var appliedPolicies: [CachePolicy] = []
    var inspector: (() -> Void)?
    var policyInspector: (([CachePolicy]) -> Void)?

    var removeValuesCount = 0
    var removeAllCount = 0
    var setAccessDateCount = 0
    var applyCount = 0
    let policies: [CachePolicy]
    var config: CacheConfig?

    init(policies: [CachePolicy] = []) {
        self.policies = policies
    }

    func setup(config: CacheConfig) {
        self.config = config
    }

    func items(for keys: Set<Key>, accessDate: Date) -> [Item] {
        keysProcessed += keys

        var items: [Item] = []

        let date = Date()

        for key in keys {
            if let value = cache[key] {
                items.append(Item(key: key, creationDate: date, lastAccessDate: date, value: value))
            }
        }

        return items
    }

    func set(_ items: [CacheItem<String, MockCacheValue>]) {
        keysSet += items.map { $0.key }

        for item in items {
            cache[item.key] = item.value
        }
    }

    func removeValues(for keys: Set<Key>) {
        removeValuesCount += 1
        for key in keys {
            cache.removeValue(forKey: key)
        }
    }

    func removeAll() {
        removeAllCount += 1
        cache.removeAll()
    }

    // MARK: Housekeeping

    func setLastAccessDate(for keys: Set<Key>, to date: Date) {
        setAccessDateCount += 1
    }

    func apply(_ policies: [CachePolicy]) {
        applyCount += 1
        policyInspector?(policies)
        appliedPolicies += policies
    }

    var keys: [Key] {
        return Array(cache.keys)
    }

    var values: [Value] {
        return Array(cache.values)
    }
}
