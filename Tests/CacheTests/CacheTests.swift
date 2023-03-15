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
import Gauntlet
import XCTest

final class CacheTestCases: XCTestCase {
    typealias TestMemoryCache = Cache<String, String>

    // swiftlint:disable:next force_try
    let location = try! CacheLocation(locationName: "CacheTestCases")

    override func setUpWithError() throws {
        super.setUp()

        // Cleanup from any previous tests.
        try? CodableFile<Data>.delete("MemoryCacheLayer.json", directory: location.directory)

    }

    override func tearDown() {
        super.tearDown()

        // Cleanup from any previous tests.
        try? CodableFile<Data>.delete("MemoryCacheLayer.json", directory: location.directory)
    }

    func testInit() throws {
        // Given/When
        let policies: [CachePolicy] = [.maxItemCount(42), .maxItemLifetime(123)]
        let cache = TestMemoryCache(policies: policies, identifier: #function)

        // Then
        XCTAssertEqual(cache.layer.policies, policies)
        XCTAssertEqual(cache.identifier, #function)
    }

    func testValuesForKeysHit() throws {
        // Given
        let cache = TestMemoryCache(policies: [], identifier: #function)
        XCTAssertTrue(cache.layer.cache.isEmpty)

        cache.set(value: "World", for: "Hello")

        // When
        let results = cache.values(for: ["Hello"])

        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results["Hello"], "World")
    }

    func testValuesForKeysMiss() throws {
        // Given
        let cache = TestMemoryCache(policies: [], identifier: #function)
        XCTAssertTrue(cache.layer.cache.isEmpty)

        cache.set(value: "World", for: "Hello")

        // When
        let results = cache.values(for: ["Foo"])

        // Then
        XCTAssertTrue(results.isEmpty)
    }

    func testValueForKeyHit() throws {
        // Given
        let cache = TestMemoryCache(policies: [], identifier: #function)
        XCTAssertTrue(cache.layer.cache.isEmpty)

        cache.set(value: "World", for: "Hello")

        // When
        let result = cache.value(for: "Hello")

        // Then
        XCTAssertEqual(result, "World")
    }

    func testValueForKeyMiss() throws {
        // Given
        let cache = TestMemoryCache(policies: [], identifier: #function)
        XCTAssertTrue(cache.layer.cache.isEmpty)

        cache.set(value: "World", for: "Hello")

        // When
        let result = cache.value(for: "Foo")

        // Then
        XCTAssertNil(result)
    }

    func testValuesForKeysExpiresOldItems() throws {
        // Given
        let cache = TestMemoryCache(policies: [.maxItemLifetime(0.5)], identifier: #function)
        XCTAssertTrue(cache.layer.cache.isEmpty)

        cache.set(value: "World", for: "Hello")

        // When
        var result = cache.value(for: "Hello")

        // Then
        XCTAssertEqual(result, "World")

        // When
        Thread.sleep(forTimeInterval: 1.0)
        result = cache.value(for: "Hello")

        // Then
        XCTAssertNil(result)
    }

    func testSetValueForKey() {
        // Given
        let cache = TestMemoryCache(policies: [], identifier: #function)
        XCTAssertTrue(cache.layer.cache.isEmpty)

        cache.set(value: "World", for: "Hello")
        cache.set(value: "Bar", for: "Foo")

        // When
        let result = cache.value(for: "Hello")

        // Then
        XCTAssertEqual(result, "World")
    }

    func testSubscript() {
        // Given
        let cache = TestMemoryCache(policies: [], identifier: #function)
        XCTAssertTrue(cache.layer.cache.isEmpty)

        cache["Hello"] = "World"
        cache["Foo"] = "Bar"

        // When
        let result = cache["Hello"]

        // Then
        XCTAssertEqual(result, "World")
    }

    func testRemoveSubscript() {
        // Given
        let cache = TestMemoryCache(policies: [], identifier: #function)
        XCTAssertTrue(cache.layer.cache.isEmpty)

        cache["Hello"] = "World"
        XCTAssertEqual(cache["Hello"], "World")

        // When
        cache["Hello"] = nil

        // Then
        XCTAssertNil(cache["Hello"])
    }

    func testSetDictionary() throws {
        // Given
        let cache = TestMemoryCache(policies: [], identifier: #function)
        XCTAssertTrue(cache.layer.cache.isEmpty)

        cache.set(["Hello": "World", "Foo": "Bar"])

        // When
        let results = cache.values(for: ["Hello", "Foo"])

        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results["Hello"], "World")
        XCTAssertEqual(results["Foo"], "Bar")
    }

    func testRemoveValues() throws {
        // Given
        let cache = TestMemoryCache(policies: [], identifier: #function)
        XCTAssertTrue(cache.layer.cache.isEmpty)

        cache.set(value: "World", for: "Hello")
        cache.set(value: "Bar", for: "Foo")

        // When
        cache.removeValues(for: ["Hello"])
        let results = cache.values(for: ["Hello", "Foo"])

        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results["Foo"], "Bar")
    }

    func testRemoveAll() throws {
        // Given
        let cache = TestMemoryCache(policies: [], identifier: #function)
        XCTAssertTrue(cache.layer.cache.isEmpty)

        cache.set(value: "World", for: "Hello")
        cache.set(value: "Bar", for: "Foo")

        // When
        cache.removeAll()
        let results = cache.values(for: ["Hello", "Foo"])

        // Then
        XCTAssertTrue(results.isEmpty)
    }

    func testSaveAndLoad() throws {
        // Given
        var cache: TestMemoryCache? = TestMemoryCache(policies: [], identifier: #function, location: location)
        XCTAssertNotNil(cache) { cache in
            XCTAssertTrue(cache.layer.cache.isEmpty)

            cache.set(value: "World", for: "Hello")
            XCTAssertEqual(cache["Hello"], "World")
        }

        // When
        cache = nil
        cache = TestMemoryCache(policies: [], identifier: #function, location: location)

        // Then
        XCTAssertNotNil(cache) { cache in
            XCTAssertEqual(cache["Hello"], "World")
        }
    }
}
