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

class CacheLocationTests: XCTestCase {
    func testInit() throws {
        // Given, When
        let location = try CacheLocation(locationName: "Hello")
        let dataDirectory = PersistenceLocation.cache(subpath: "Hello")

        // Then
        XCTAssertEqual(location.locationName, "Hello")
        XCTAssertEqual(location.url.lastPathComponent, "Hello")
        XCTAssertEqual(try? location.directory.url(), try? dataDirectory.url())
        XCTAssertTrue(FileManager.default.fileExists(atPath: location.url.path))

        try location.remove()
    }

    func testInitWithExistingDirectory() throws {
        // Given
        let location = try CacheLocation(locationName: "Hello")

        // When, Then
        _ = try CacheLocation(locationName: "Hello")

        // Same name, just remove one...
        try location.remove()
    }

    func testInitWithParent() throws {
        // Given
        let location1 = try CacheLocation(locationName: "Directory1")

        // When
        let location2 = try CacheLocation(locationName: "Directory2", parentURL: location1.url)
        let location2URL = location2.url
        let dataDirectoryURL = try location2.directory.url()

        // Then
        XCTAssertEqual(location2.locationName, "Directory2")
        XCTAssertEqual(location2URL, dataDirectoryURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: location1.url.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: location2.url.path))

        let baseURL = try PersistenceLocation.cache.url()
        let basePath = baseURL.path

        XCTAssertEqual(location2URL.path.hasPrefix(basePath), true) {
            let location2Subpath = location2URL.path.dropFirst(basePath.count)

            XCTAssertEqual(location2Subpath, "/Directory1/Directory2")
        }

        XCTAssertEqual(dataDirectoryURL.path.hasPrefix(basePath), true) {
            let location2Subpath = location2URL.path.dropFirst(basePath.count)

            XCTAssertEqual(location2Subpath, "/Directory1/Directory2")
        }

        try location1.remove()
        XCTAssertFalse(FileManager.default.fileExists(atPath: location1.url.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: location2.url.path))
    }

    func testRemoveAndCreate() throws {
        // Given
        let directory = try CacheLocation(locationName: "Hello")

        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.url.path))

        // When
        try directory.remove()
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.url.path))
        try directory.create()

        // Then
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.url.path))
        try directory.remove()
    }

    func testRemoveAndCreateNested() throws {
        // Given
        let location1 = try CacheLocation(locationName: "Directory1")
        let location2 = try CacheLocation(locationName: "Directory2", parentURL: location1.url)

        // When, Then
        try location2.remove()
        XCTAssertTrue(FileManager.default.fileExists(atPath: location1.url.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: location2.url.path))
        try location1.remove()
        XCTAssertFalse(FileManager.default.fileExists(atPath: location1.url.path))

        try location2.create()
        XCTAssertTrue(FileManager.default.fileExists(atPath: location1.url.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: location2.url.path))

        // Then
        try location1.remove()
        XCTAssertFalse(FileManager.default.fileExists(atPath: location1.url.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: location2.url.path))
    }
}
