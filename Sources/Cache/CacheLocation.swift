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

/// Specifies a directory where ``CacheLayer``s are stored.
public struct CacheLocation {
    /// Name of this location.
    public let locationName: String

    /// ``URL`` for this directory.
    public let url: URL

    /// ``PersistenceLocation`` for this directory.
    let directory: PersistenceLocation

    /// Create a ``CacheLocation``. This is a directory where all of the files for a given cache will exist.
    /// - Parameters:
    ///   - locationName:   Name of the location.
    ///   - parentURL:      Parent location. Defaults to OS cache folder if `nil`.
    public init(locationName name: String, parentURL: URL? = nil) throws {
        self.locationName = name

        let cacheURL = try PersistenceLocation.cache.url()
        let parentURL = parentURL ?? cacheURL

        // This will be a subdirectory of the parent.
        url = parentURL.appendingPathComponent(name, isDirectory: true)

        directory = PersistenceLocation.other(path: url.path)

        // Create the folder.
        try create()
    }

    /// Attempt to remove the directory and it's contents.
    ///
    /// **Note**: DO NOT REMOVE THE DIRECTORY OF AN ACTIVE CACHE.
    public func remove() throws {
        try FileManager.default.removeItem(at: url)
    }

    /// Create the underlying directory if it does not already exist.
    public func create() throws {
        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
    }
}
