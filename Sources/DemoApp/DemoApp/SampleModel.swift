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

import Cache
import Combine
import SwiftUI

enum SampleProduct: String, CaseIterable, Identifiable, Comparable, Codable {
    case product1
    case product2
    case product3
    case product4
    case product5

    var id: Self { self }

    static func < (lhs: SampleProduct, rhs: SampleProduct) -> Bool { lhs.rawValue < rhs.rawValue }
}

struct ProductInfo: Codable {
    let product: SampleProduct
    let name: String
}

// Object responsible for providing product information.
// Typically this would be a network call.
struct ProductProvider {
    func getInfo(for product: SampleProduct, _ completion: @escaping (ProductInfo) -> Void) {
        let info: ProductInfo

        switch product {
        case .product1:
            info = ProductInfo(product: product, name: "Ketchup")

        case .product2:
            info = ProductInfo(product: product, name: "Mustard")

        case .product3:
            info = ProductInfo(product: product, name: "Eggs")

        case .product4:
            info = ProductInfo(product: product, name: "Milk")

        case .product5:
            info = ProductInfo(product: product, name: "Bread")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            completion(info)
        }
    }
}

// Sample view model that manages the selected product and the fetched details for that product.
class SampleModel: ObservableObject {
    // The currently selected product and it's details.
    @Published var selectedProduct: SampleProduct = .product3
    @Published private(set) var productInfo: ProductInfo?

    // Sample data provider.
    private let provider = ProductProvider()

    // The cache.
    private var cache = Cache<SampleProduct, ProductInfo>(
        policies: [
            .maxItemCount(4),
            .maxItemLifetime(10.0)
        ],
        identifier: "demo"
    )
    private var cancellables: Set<AnyCancellable> = []

    init() {
        // When the selected product changes, update the product info.
        $selectedProduct.sink { [weak self] product in
            guard let self else { return }

            // If the info is in the cache, update immediately.
            if let info = self.cache[product] {
                self.productInfo = info
            } else {
                // Info not in the cache. Fetch the info and update when complete.
                self.productInfo = nil
                self.provider.getInfo(for: product) { info in
                    // Update the cache.
                    self.cache[product] = info

                    // Publish the info.
                    self.productInfo = info
                }
            }
        }
        .store(in: &cancellables)

        // Print debug messages from the cache.
        cache.events.sink { event in
            switch event {
            case .maxCountExceeded(let count):
                print("Cache maximum item count exceeded. \(count) items were evicted.")

            case .maxLifetimeExceeded(let count):
                print("Cache maximum item lifetime exceeded. \(count) items were evicted.")

            case .unableToLoad(let url, let error):
                print("Unable to load from file at: \(url.path): \(error)")

            case .unableToSave(let url, let error):
                let path = url?.path ?? "<unknown>"
                print("Unable to save to file at: \(path): \(error)")
            }
        }
        .store(in: &cancellables)
    }
}
