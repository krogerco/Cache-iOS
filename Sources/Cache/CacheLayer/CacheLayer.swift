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

/// A type representing a layer in a larger cache system.
protocol CacheLayer {
    associatedtype Key: CacheKey
    associatedtype Value: Codable

    typealias Item = CacheItem<Key, Value>

    /// The policies in place on this cache layer.
    var policies: [CachePolicy] { get }

    /// Called by the Cache to complete setup of this layer to prepare it for use.
    /// - Parameter config: Configuration information for the Cache.
    func setup(config: CacheConfig)

    /// Get the items for a given set of keys.
    /// Subclasses should override this method to provide items for the passed keys.
    /// - Parameters:
    ///   - keys:       Keys to query.
    ///   - accessDate: The access date to associate with this access.
    ///   - queue:      Queue to execute the completion on.
    ///
    /// - Returns: Results of the query. Returned items can be in any order.
    ///            Keys with no data will be missing from the results.
    func items(for keys: Set<Key>, accessDate: Date) -> [Item]

    /// Add the passed items to this cache.
    /// - Parameter items: Items to add.
    func set(_ items: [Item])

    /// Remove the current values (if any) for the passed keys.
    /// - Parameter keys: Keys for which values should be removed.
    func removeValues(for keys: Set<Key>)

    /// Remove all values from the cache.
    func removeAll()

    // MARK: Housekeeping

    /// Set the `lastAccessDate` for the passed keys.
    /// - Parameters:
    ///   - keys: Keys on which to set the date.
    ///   - date: The date.
    func setLastAccessDate(for keys: Set<Key>, to date: Date)

    /// Apply the passed policies to the cache.
    /// - Parameter policies: Policies to be applied.
    func apply(_ policies: [CachePolicy])
}

// MARK: -

extension CacheLayer {
    func applySizePolicies() {
        let sizePolicies = self.policies.filter { $0.policyType == .size }

        apply(sizePolicies)
    }

    func applyTemporalPolicies() {
        let temporalPolicies = self.policies.filter { $0.policyType == .temporal }

        apply(temporalPolicies)
    }
}
