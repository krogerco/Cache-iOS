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

import SwiftUI

struct ContentView: View {
    @StateObject var model = SampleModel()

    var body: some View {
        NavigationStack {
            VStack {
                Text("Cache Demo")
                    .font(.largeTitle)
                    .padding([.bottom], 24.0)

                VStack(alignment: .leading) {
                    // swiftlint:disable:next line_length
                    Text("Select a product in the picker. The name label will update immediately if the value is in the cache.")
                        .padding([.bottom], 6.0)

                    Text("Maximum items allowed in cache: 4")
                        .font(.caption)

                    Text("Maximum lifetime (in seconds) allowed in cache: 10.0")
                        .font(.caption)
                }

                Divider()

                Picker("Product", selection: $model.selectedProduct) {
                    ForEach(SampleProduct.allCases) { product in
                        Text(product.rawValue)
                    }
                }
                .pickerStyle(.inline)

                Divider()

                if let name = model.productInfo?.name {
                    Text("Name: \(name)")
                } else {
                    ProgressView()
                }

                Spacer()
            }
        }
    }
}
