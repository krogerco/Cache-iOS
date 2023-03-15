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

/// Policies that may be applied to each cache source.
/// Generally, you would create a different and more lenient policy for each level of cache source.
/// Specifying no policies results in caches with unbounded growth.
public enum CachePolicy {
    /// The maximum number of key/values the source should track.
    /// When this count is exceeded, the least recently used values will be purged.
    case maxItemCount(Int)

    /// The maximum time a value should remain in the source.
    /// Values that have been in the cache longer than this will be purged.
    case maxItemLifetime(TimeInterval)

    /// Categories of policies.
    enum PolicyType: Equatable {
        case size
        case temporal
    }

    /// The type of policy this represents.
    var policyType: PolicyType {
        switch self {
        case .maxItemCount:     return .size
        case .maxItemLifetime:  return .temporal
        }
    }
}

extension CachePolicy: Equatable {}
