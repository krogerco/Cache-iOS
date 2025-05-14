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

import GauntletLegacy
@testable import Cache
import XCTest

class CodableFileTestCase: XCTestCase {
    let filename = "TestFile.txt"

    typealias TestFile = CodableFile<TestStruct>

    func makeTestDate(for file: TestFile) -> Date {
        let components = DateComponents(
            calendar: Calendar.current,
            year: 2019,
            month: 10,
            day: 09,
            hour: 15,
            minute: 38,
            second: 10,
            nanosecond: 123000000
        )
        let date = components.date!

        // Round trip the date through the formatter to ensure the rounding and precision of the fractional seconds
        // does not exceed the precision of the formatter string.
        // Without this, the .123 seconds above will become .122999 and the dates will not be equal.
        let roundTrippedDate = file.dateFormatter.date(from: file.dateFormatter.string(from: date))!

        return roundTrippedDate
    }

    override func setUp() {
        super.setUp()

        try? TestFile.delete(filename, directory: .documents)
        try? TestFile.delete(filename, directory: .cache)
    }

    func testSaveLoadDocuments() throws {
        // Given
        let file = TestFile(name: filename, directory: .documents)
        let date = makeTestDate(for: file)
        let sourceData = TestStruct(date: date)

        // When
        try file.save(sourceData)

        let resultData: TestStruct = try file.load()

        // Then
        XCTAssertEqual(resultData.hello, sourceData.hello)
        XCTAssertEqual(resultData.value, sourceData.value)
        XCTAssertEqual(resultData.date, sourceData.date)
    }

    func testSaveLoadCache() throws {
        // Given
        let file = TestFile(name: filename, directory: .cache)
        let date = makeTestDate(for: file)
        let sourceData = TestStruct(date: date)

        // When
        try file.save(sourceData)

        let resultData: TestStruct = try file.load()

        // Then
        XCTAssertEqual(resultData.hello, sourceData.hello)
        XCTAssertEqual(resultData.value, sourceData.value)
        XCTAssertEqual(resultData.date, sourceData.date)
    }

    func testMissingFile() throws {
        // Given
        let file = TestFile(name: filename, directory: .documents)

        // When, Then
        XCTAssertThrowsError(try file.load())
    }

    func testLoadWrongType() throws {
        // Given
        let file = TestFile(name: filename, directory: .documents)
        let sourceData = TestStruct()

        // When
        try file.save(sourceData)

        let stringfile = CodableFile<String>(name: filename, directory: .documents)

        XCTAssertThrowsError(try stringfile.load())
    }

    func testExists() throws {
        // Given
        let file = TestFile(name: filename, directory: .documents)
        let sourceData = TestStruct()

        // When
        XCTAssertFalse(try file.exists())
        try file.save(sourceData)

        // Then
        XCTAssertTrue(try file.exists())
        XCTAssertTrue(try TestFile.exists(filename, directory: .documents))
    }

    func testDeleteFile() throws {
        // Given
        let file = TestFile(name: filename, directory: .documents)
        let sourceData = TestStruct()
        try file.save(sourceData)

        // When
        try file.delete()

        // Then
        XCTAssertFalse(try file.exists())
    }

    func testDeleteMissingFile() throws {
        // Given
        let file = TestFile(name: filename, directory: .documents)

        // When, Then
        XCTAssertThrowsError(try file.delete())
    }

    func testOtherPath() throws {
        // Given
        let file = TestFile(name: filename, directory: .other(path: "/tmp"))
        let sourceData = TestStruct()

        // When
        try file.save(sourceData)

        let resultData: TestStruct = try file.load()

        // Then
        XCTAssertEqual(resultData.hello, "Hello")
        XCTAssertEqual(resultData.value, 42)
    }

    func testAlternateDateFormatter() throws {
        // Given
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.timeZone = TimeZone(identifier: "UTC")

        // When
        let file = TestFile(name: filename, directory: .documents, dateFormatter: formatter)

        // Then
        if case let .formatted(decoderFormatter) = file.decoder.dateDecodingStrategy {
            XCTAssertIdentical(decoderFormatter, formatter)
        } else {
            XCTFail("Unexpected dateDecodingStrategy: \(file.decoder.dateDecodingStrategy)")
        }

        if case let .formatted(encoderFormatter) = file.encoder.dateEncodingStrategy {
            XCTAssertIdentical(encoderFormatter, formatter)
        } else {
            XCTFail("Unexpected dateEncodingStrategy: \(file.encoder.dateEncodingStrategy)")
        }
    }

    func testSaveLoadOptionalDocuments() throws {
        // Given
        let sourceData: TestStruct? = TestStruct()
        let file = CodableFile<TestStruct?>(name: filename, directory: .documents)

        // When
        try file.save(sourceData)

        // Then
        XCTAssertNotNil(try file.load()) { resultData in
            XCTAssertEqual(resultData.hello, sourceData?.hello)
            XCTAssertEqual(resultData.value, sourceData?.value)
        }
    }

    func testSaveNilLoadOptionalDocuments() throws {
        // Given
        let sourceData: TestStruct? = TestStruct()
        let file = CodableFile<TestStruct?>(name: filename, directory: .documents)

        // When
        try file.save(sourceData)

        if #available(*, macOS 10.15) {
            try file.save(nil)
            let resultData: TestStruct? = try file.load()

            // Then
            XCTAssertNil(resultData)
        } else {
            // Currently broken in macOS
            XCTAssertThrowsError(try file.save(nil))
        }
    }

    func testOutputFormatting() throws {
        // Given, When
        let file = TestFile(
            name: filename,
            directory: .documents,
            outputFormatting: [.prettyPrinted, .sortedKeys]
        )

        // Then
        XCTAssertEqual(file.encoder.outputFormatting, [.prettyPrinted, .sortedKeys])
    }
}

// MARK: -

struct TestStruct {
    let hello: String
    let value: Int
    let date: Date

    init(hello: String = "Hello", value: Int = 42, date: Date = Date()) {
        self.hello = hello
        self.value = value
        self.date = date
    }
}

extension TestStruct: Codable {}
