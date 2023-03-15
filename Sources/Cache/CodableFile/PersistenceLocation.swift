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

/// The location of the file.
struct PersistenceLocation: Equatable {
    /// Errors that can occur during url construction.
    enum DirectoryError: Error {

        /// The directory could not be found for this case.
        case directoryDoesNotExist
    }

    /// The application document folder. Can be backed up by the OS.
    static let documents = PersistenceLocation(.documentDirectory)

    /// The cache folder. Not backed up. May be deleted by the OS.
    static let cache = PersistenceLocation(.cachesDirectory)

    /// A subpath in the application documents folder. Can be backed up by the OS.
    static func documents(subpath: String) -> PersistenceLocation {
        PersistenceLocation(.documentDirectory, subpath: subpath)
    }

    /// A subpath in the cache folder. Not backed up. May be deleted by the OS.
    static func cache(subpath: String) -> PersistenceLocation {
        PersistenceLocation(.cachesDirectory, subpath: subpath)
    }

    /// A custom destination. The associated `path` is the directory path in which to store the file.
    static func other(path: String) -> PersistenceLocation {
        PersistenceLocation(subpath: path)
    }

    /// Directory to the search path for this case.
    let searchDirectory: FileManager.SearchPathDirectory?

    let subpath: String?

    init(_ search: FileManager.SearchPathDirectory? = nil, subpath: String? = nil) {
        searchDirectory = search
        self.subpath = subpath
    }

    /// Constructs file path url to the directory for this case.
    ///
    /// - Throws: ``Directory.DirectoryError``
    func url() throws -> URL {
        if let searchDirectory = searchDirectory {
            let urls = FileManager.default.urls(for: searchDirectory, in: .userDomainMask)
            guard let baseURL = urls.first else { throw DirectoryError.directoryDoesNotExist }
            let url: URL

            if let subpath = subpath {
                url = baseURL.appendingPathComponent(subpath)
            } else {
                url = baseURL
            }

            return url
        } else {
            guard let subpath = subpath else { throw DirectoryError.directoryDoesNotExist }
            return URL(fileURLWithPath: subpath)
        }
    }
}
