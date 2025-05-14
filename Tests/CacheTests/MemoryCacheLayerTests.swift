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
import GauntletLegacy
import XCTest

class MemoryCacheLayerTestCase: XCTestCase {
    typealias Item = CacheItem<String, MockCacheValue>
    typealias TestMemoryCache = MemoryCacheLayer<String, MockCacheValue>

    // swiftlint:disable:next force_try
    let location = try! CacheLocation(locationName: "MemoryCacheLayerTestCase")

    override func setUp() {
        super.setUp()

        // Cleanup from any previous tests.
        try? CodableFile<Data>.delete("MemoryCacheLayer.json", directory: location.directory)
    }

    override func tearDown() {
        super.tearDown()

        // Cleanup from any previous tests.
        try? CodableFile<Data>.delete("MemoryCacheLayer.json", directory: location.directory)
    }

    func testSetup() throws {
        // Given
        let cache = TestMemoryCache()

        // When
        cache.setup(config: CacheConfig(location: location))

        // Then
        XCTAssertNotNil(cache.file) { file in
            XCTAssertNotNil(file.url) { url in
                XCTAssertEqual(url.lastPathComponent, "MemoryCacheLayer.json")
            }
            XCTAssertEqual(try? file.exists(), false)
        }
        XCTAssertFalse(cache.needsSave)
    }

    func testSave() throws {
        // Given
        let cache = TestMemoryCache()
        cache.setup(config: CacheConfig(location: location))

        // When
        cache.save()
        XCTAssertEqual(try? cache.file?.exists(), false)
        cache.needsSave = true
        cache.save()

        // Then
        XCTAssertEqual(try? cache.file?.exists(), true)
    }

    func testMarkDirty() {
        // Given
        let cache = TestMemoryCache()
        cache.setup(config: CacheConfig(location: location))
        XCTAssertFalse(cache.needsSave)

        // When
        cache.markDirty()

        // Then
        XCTAssertTrue(cache.needsSave)
    }

    func testValuesForKeysHit() {
        // Given
        let cache = TestMemoryCache()
        let testStruct = MockCacheValue(name: "Alice", address: "1234", date: Date())
        let date = Date()
        let item = Item(key: testStruct.name, creationDate: date, lastAccessDate: date, value: testStruct)

        cache.setup(config: CacheConfig())
        cache.cache["Alice"] = item

        // When
        let items = cache.items(for: ["Alice"], accessDate: Date())

        // Then
        XCTAssertEqual(items.count, 1)
        let dict = Dictionary(uniqueKeysWithValues: items.map { ($0.key, $0.value) })

        XCTAssertEqual(dict["Alice"], item.value)
        XCTAssertTrue(cache.needsSave)
    }

    func testValuesForKeysMiss() {
        // Given
        let cache = TestMemoryCache()

        cache.setup(config: CacheConfig())

        // When
        XCTAssertFalse(cache.needsSave)

        let items = cache.items(for: ["Alice"], accessDate: Date())

        // Then
        XCTAssertEqual(items.count, 0)
        XCTAssertFalse(cache.needsSave)
    }

    func testSetItems() {
        // Given
        let cache = TestMemoryCache()
        let testStruct = MockCacheValue(name: "Alice", address: "1234", date: Date())
        let date = Date()
        let item = Item(key: testStruct.name, creationDate: date, lastAccessDate: date, value: testStruct)

        cache.setup(config: CacheConfig())
        cache.set([item])

        // When
        let items = cache.items(for: ["Alice"], accessDate: Date())

        // Then
        XCTAssertEqual(items.count, 1)
        let dict = Dictionary(uniqueKeysWithValues: items.map { ($0.key, $0.value) })
        XCTAssertEqual(dict["Alice"], item.value)
        XCTAssertTrue(cache.needsSave)
    }

    func testRemoveValues() {
        // Given
        let cache = TestMemoryCache()
        let testStruct1 = MockCacheValue(name: "Alice", address: "1234", date: Date())
        let testStruct2 = MockCacheValue(name: "Bob", address: "5678", date: Date())
        let date = Date()
        let item1 = Item(key: testStruct1.name, creationDate: date, lastAccessDate: date, value: testStruct1)
        let item2 = Item(key: testStruct2.name, creationDate: date, lastAccessDate: date, value: testStruct2)

        cache.setup(config: CacheConfig())
        cache.cache["Alice"] = item1
        cache.cache["Bob"] = item2

        let items = cache.items(for: ["Alice", "Bob"], accessDate: Date())

        XCTAssertEqual(items.count, 2)
        let dict = Dictionary(uniqueKeysWithValues: items.map { ($0.key, $0.value) })
        XCTAssertNotNil(dict["Alice"])
        XCTAssertNotNil(dict["Bob"])

        XCTAssertEqual(cache.cache["Alice"]?.value, testStruct1)
        XCTAssertEqual(cache.cache["Bob"]?.value, testStruct2)

        // When
        XCTAssertTrue(cache.needsSave)
        cache.needsSave = false
        cache.removeValues(for: ["Alice"])
        XCTAssertTrue(cache.needsSave)

        // Then
        XCTAssertNil(cache.cache["Alice"]?.value)
        XCTAssertEqual(cache.cache["Bob"]?.value, testStruct2)
    }

    func testRemoveAll() {
        // Given
        let cache = TestMemoryCache()
        let testStruct1 = MockCacheValue(name: "Alice", address: "1234", date: Date())
        let testStruct2 = MockCacheValue(name: "Bob", address: "5678", date: Date())
        let date = Date()
        let item1 = Item(key: testStruct1.name, creationDate: date, lastAccessDate: date, value: testStruct1)
        let item2 = Item(key: testStruct2.name, creationDate: date, lastAccessDate: date, value: testStruct2)

        cache.setup(config: CacheConfig())
        cache.cache["Alice"] = item1
        cache.cache["Bob"] = item2

        let items = cache.items(for: ["Alice", "Bob"], accessDate: Date())

        XCTAssertEqual(items.count, 2)
        let dict = Dictionary(uniqueKeysWithValues: items.map { ($0.key, $0.value) })
        XCTAssertEqual(dict["Alice"], item1.value)
        XCTAssertEqual(dict["Bob"], item2.value)

        XCTAssertEqual(cache.cache["Alice"]?.value, testStruct1)
        XCTAssertEqual(cache.cache["Bob"]?.value, testStruct2)

        // When
        XCTAssertTrue(cache.needsSave)
        cache.needsSave = false
        cache.removeAll()
        XCTAssertTrue(cache.needsSave)

        // Then
        XCTAssertNil(cache.cache["Alice"]?.value)
        XCTAssertNil(cache.cache["Bob"]?.value)
    }

    func testSetLastAccessDate() {
        // Given
        let cache = TestMemoryCache()
        let testStruct = MockCacheValue(name: "Alice", address: "1234", date: Date())
        let creationDate = Date()
        let item = Item(
            key: testStruct.name,
            creationDate: creationDate,
            lastAccessDate: creationDate,
            value: testStruct
        )

        cache.setup(config: CacheConfig())
        cache.cache["Alice"] = item

        let items = cache.items(for: ["Alice"], accessDate: Date())

        XCTAssertEqual(items.count, 1) {
            XCTAssertEqual(items[0], item)
        }

        XCTAssertTrue(cache.needsSave)

        // When
        let date = Date(timeIntervalSinceNow: 60.0)
        cache.needsSave = false
        cache.setLastAccessDate(for: ["Alice"], to: date)
        XCTAssertTrue(cache.needsSave)

        // Then
        XCTAssertEqual(cache.cache["Alice"]?.lastAccessDate, date)
    }

    func testMaxCountPolicy() {
        // Given
        let cache = TestMemoryCache(policies: [.maxItemCount(1)])
        let testStruct1 = MockCacheValue(name: "Alice", address: "1234", date: Date())
        let testStruct2 = MockCacheValue(name: "Bob", address: "5678", date: Date())
        let date = Date()
        let item1 = Item(key: testStruct1.name, creationDate: date, lastAccessDate: date, value: testStruct1)
        let item2 = Item(key: testStruct2.name, creationDate: date, lastAccessDate: date, value: testStruct2)

        cache.setup(config: CacheConfig())
        cache.cache["Alice"] = item1

        // When
        // Update the lastAccessDate
        let items = cache.items(for: ["Alice"], accessDate: Date())

        XCTAssertEqual(items.count, 1) {
            XCTAssertEqual(items[0], item1)
        }

        // This should not change anything
        cache.apply(cache.policies)

        // Then
        XCTAssertEqual(cache.cache.count, 1)
        XCTAssertEqual(cache.cache["Alice"]?.value, testStruct1)

        // When
        cache.cache["Bob"] = item2
        let items2 = cache.items(for: ["Bob"], accessDate: Date())

        XCTAssertEqual(items2.count, 1)
        XCTAssertEqual(items2[0], item2)

        XCTAssertEqual(cache.cache.count, 2)

        cache.needsSave = false
        cache.apply(cache.policies)

        // Then
        XCTAssertTrue(cache.needsSave)
        XCTAssertEqual(cache.cache.count, 1)
        XCTAssertEqual(cache.cache["Bob"]?.value, testStruct2)
    }

    func testMaxTimePolicy() {
        // Given
        let cache = TestMemoryCache(policies: [.maxItemLifetime(60)])
        let testStruct1 = MockCacheValue(name: "Alice", address: "1234", date: Date())
        let testStruct2 = MockCacheValue(name: "Bob", address: "5678", date: Date())
        let date = Date()
        let item1 = Item(key: testStruct1.name, creationDate: date, lastAccessDate: date, value: testStruct1)
        let item2 = Item(key: testStruct2.name, creationDate: date, lastAccessDate: date, value: testStruct2)

        cache.setup(config: CacheConfig())
        cache.cache["Alice"] = item1
        cache.cache["Bob"] = item2

        XCTAssertEqual(cache.cache.count, 2)
        XCTAssertEqual(cache.cache["Alice"]?.value, testStruct1)
        XCTAssertEqual(cache.cache["Bob"]?.value, testStruct2)
        XCTAssertFalse(cache.needsSave)

        // When
        let newDate = Date(timeIntervalSinceNow: -62)
        let newItem = Item(key: "Alice", creationDate: newDate, lastAccessDate: newDate, value: testStruct1)
        cache.cache["Alice"] = newItem
        cache.needsSave = false

        cache.apply(cache.policies)

        // Then
        XCTAssertTrue(cache.needsSave)
        XCTAssertEqual(cache.cache.count, 1)
        XCTAssertEqual(cache.cache["Bob"]?.value, testStruct2)
    }

    func testLoadFromFile() {
        // Given
        var cache = TestMemoryCache()
        cache.setup(config: CacheConfig(location: location))

        let testStruct = MockCacheValue(name: "Alice", address: "1234", date: Date())
        let date = Date()
        let item = Item(key: testStruct.name, creationDate: date, lastAccessDate: date, value: testStruct)

        cache.cache["Alice"] = item

        // When
        cache.needsSave = true
        cache.save()

        cache = MemoryCacheLayer()
        XCTAssertEqual(cache.cache.count, 0)

        cache.setup(config: CacheConfig(location: location))

        // Then
        XCTAssertEqual(cache.cache.count, 1)
        XCTAssertEqual(cache.cache["Alice"]?.value.name, testStruct.name)
    }
}
