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

/// This is the internal wrapper for a value stored in a cache.
final class CacheItem<Key: CacheKey, Value: Codable>: Codable {
    /// The key for this item.
    let key: Key

    /// Date this item was created.
    let creationDate: Date

    /// Last time this item was accessed.
    var lastAccessDate: Date

    /// The value for the key.
    var value: Value

    /// Create a ``CacheItem``.
    /// - Parameters:
    ///   - key:            The key for this item.
    ///   - creationDate:   Date this item was created.
    ///   - lastAccessDate: Last time this item was accessed.
    ///   - value:          The value for the key.
    init(key: Key, creationDate: Date, lastAccessDate: Date, value: Value) {
        self.key = key
        self.creationDate = creationDate
        self.lastAccessDate = lastAccessDate
        self.value = value
    }
}
