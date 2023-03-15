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

import Foundation

/// Class for encoding/decoding entities to files on disk.
class CodableFile<T: Codable> {
    /// Name of the file.
    let name: String

    /// Directory the file is in.
    let directory: PersistenceLocation

    /// File URL for the file.
    var url: URL? { try? directory.url().appendingPathComponent(name) }

    /// DateFormatter to use when loading and saving. Defaults to`yyyy-MM-dd'T'HH:mm:ss.SSSZ`.
    let dateFormatter: DateFormatter

    /// The formatting options used when saving.
    let outputFormatting: JSONEncoder.OutputFormatting

    /// The decoder used to decode `T` when loading from files.
    let decoder: JSONDecoder

    /// The endcoder used to encode `T` when saving to files.
    let encoder: JSONEncoder

    /// Create a CodableFile instance
    ///
    /// - Parameters:
    ///   - name:             Name of the file.
    ///   - directory:        Where the file should be located.
    ///   - dateFormatter:    Date formatter to use. Defaults to "yyyy-MM-dd'T'HH:mm:ss.SSSZ".
    ///   - outputFormatting: The formatting options used when saving. Defaults to `[]`.
    init(
        name: String,
        directory: PersistenceLocation,
        dateFormatter: DateFormatter? = nil,
        outputFormatting: JSONEncoder.OutputFormatting = []
    ) {
        self.name = name
        self.directory = directory
        self.dateFormatter = dateFormatter ?? codableFileDateFormatter
        self.outputFormatting = outputFormatting

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(self.dateFormatter)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(self.dateFormatter)
        encoder.outputFormatting = self.outputFormatting

        self.decoder = decoder
        self.encoder = encoder
    }

    /// Load an entity from disk.
    ///
    /// - Returns: Entity.
    ///
    /// - Throws: Error for IO or decoding.
    func load() throws -> T {
        let data = try loadData()
        let object = try decoder.decode(T.self, from: data)

        return object
    }

    /// Load an entity from disk.
    ///
    /// - Returns: Entity.
    ///
    /// - Throws: Error for IO or decoding.
    func load() throws -> T where T == Data {
        try loadData()
    }

    /// Load `Data` from disk.
    ///
    /// - Returns: Data.
    ///
    /// - Throws: Error for IO or decoding.
    func loadData() throws -> Data {
        let url = try directory.url().appendingPathComponent(name)
        let data = try Data(contentsOf: url)

        return data
    }

    /// Save an entity to disk.
    ///
    /// - Parameter object: Entity to save.
    ///
    /// - Throws: Error for IO or encoding.
    func save(_ object: T) throws {
        let data = try encoder.encode(object)

        try save(data: data)
    }

    /// Save an entity to disk.
    ///
    /// - Parameter object: Entity to save.
    ///
    /// - Throws: Error for IO or encoding.
    func save(_ object: T) throws where T == Data {
        try save(data: object)
    }

    /// Save `Data` to disk.
    ///
    /// - Parameter data: Entity to save.
    ///
    /// - Throws: Error for IO or encoding.
    func save(data: Data) throws {
        let directoryURL = try directory.url()
        let url = directoryURL.appendingPathComponent(name)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)

        try data.write(to: url, options: .atomic)
    }

    /// Determine if file exists on disk.
    ///
    /// - Returns: true if file exists.
    ///
    /// - Throws: Error.
    func exists() throws -> Bool {
        try CodableFile.exists(name, directory: directory)
    }

    /// Delete the file if it exists.
    ///
    /// - Throws: Error. Note: will throw if file does not exist.
    func delete() throws {
        try CodableFile.delete(name, directory: directory)
    }

    /// Determine if file exists on disk.
    ///
    /// - Parameters:
    ///   - name:       Name of file.
    ///   - directory:  Directory to look in.
    ///
    /// - Returns: true if file exists.
    ///
    /// - Throws: Error.
    static func exists(_ name: String, directory: PersistenceLocation = .documents) throws -> Bool {
        let url = try directory.url().appendingPathComponent(name)
        let path = url.path

        return FileManager.default.fileExists(atPath: path)
    }

    /// Delete a file from the disk.
    ///
    /// - Parameters:
    ///   - name:       Name of file.
    ///   - directory:  Directory to look in.
    ///
    /// - Throws: Error. Note: will throw if file does not exist.
    static func delete(_ name: String, directory: PersistenceLocation = .documents) throws {
        let url = try directory.url().appendingPathComponent(name)

        try FileManager.default.removeItem(at: url)
    }
}

private let codableFileDateFormatter: DateFormatter = {
   let formatter = DateFormatter()
   formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
   formatter.timeZone = TimeZone(identifier: "UTC")
   return formatter
}()
