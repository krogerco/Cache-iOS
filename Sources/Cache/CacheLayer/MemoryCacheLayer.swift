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

import Combine
import Foundation

#if os(iOS)
import UIKit
#endif

/// A fully in-memory based cache with persistence.
final class MemoryCacheLayer<Key: CacheKey, Value: Codable>: CacheLayer {
    var config = CacheConfig()
    let policies: [CachePolicy]
    var cache: [Key: Item] = [:]
    var file: CodableFile<[Key: Item]>?
    var needsSave = false
    let lock = NSRecursiveLock()
    var notificationIdentifier: NSObjectProtocol?

    let savePublisher = PassthroughSubject<Void, Never>()
    var saveCancellable: AnyCancellable?

    deinit {
        save()

        if let notificationIdentifier = notificationIdentifier {
            NotificationCenter.default.removeObserver(notificationIdentifier)
            self.notificationIdentifier = nil
        }
    }

    init(policies: [CachePolicy] = []) {
        self.policies = policies
    }

    func setup(config: CacheConfig) {
        // Load from disk
        if let location = config.location {
            let file = CodableFile<[Key: Item]>(name: "MemoryCacheLayer.json", directory: location.directory)
            do {
                if try file.exists() {
                    cache = try file.load()
                }
            } catch {
                config.delegate?.logDebugMessage(
                    "MemoryCache unable to load from file \(location.url.path)",
                    error: error
                )
            }
            self.file = file
        } else {
            file = nil
        }

        // Start in a good state.
        if !cache.isEmpty {
            apply(policies)
            save()
        }

        saveCancellable = savePublisher
            .throttle(for: 5.0, scheduler: DispatchQueue.global(qos: .utility), latest: false)
            .sink { [weak self] _ in
            self?.save()
        }

#if os(iOS)
        notificationIdentifier = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let strongSelf = self else { return }

            strongSelf.lock.lock(); defer { strongSelf.lock.unlock() }

            // Bail if empty.
            guard !strongSelf.cache.isEmpty else { return }

            // Apply a policy that will purge half of the current cache.
            let purgeAmount = strongSelf.cache.count / 2
            strongSelf.apply([.maxItemCount(purgeAmount)])
        }
#endif
    }

    func save() {
        lock.lock(); defer { lock.unlock() }

        if let file = file, needsSave {
            do {
                try file.save(cache)
                needsSave = false
            } catch {
                config.delegate?.logDebugMessage(
                    "MemoryCache unable to save to file \(file.name)",
                    error: error
                )
            }
        }
    }

    func markDirty() {
        needsSave = true
        savePublisher.send(())
    }

    func items(for keys: Set<Key>, accessDate: Date) -> [CacheItem<Key, Value>] {
        lock.lock(); defer { lock.unlock() }

        let hitItems = keys.compactMap { cache[$0] }
        let hitKeys = Set(hitItems.map { $0.key })

        setLastAccessDate(for: hitKeys, to: accessDate)

        return hitItems
    }

    func set(_ items: [CacheItem<Key, Value>]) {
        lock.lock(); defer { lock.unlock() }

        for item in items {
            cache[item.key] = item
        }
        markDirty()
    }

    func removeValues(for keys: Set<Key>) {
        lock.lock(); defer { lock.unlock() }

        // Remove from local cache
        for key in keys {
            cache.removeValue(forKey: key)
        }
        markDirty()
    }

    func removeAll() {
        lock.lock(); defer { lock.unlock() }

        // Remove from local cache
        cache.removeAll()
        markDirty()
    }

    func setLastAccessDate(for keys: Set<Key>, to date: Date) {
        lock.lock(); defer { lock.unlock() }

        var needsMark = false
        for key in keys {
            if let item = cache[key] {
                item.lastAccessDate = date
                needsMark = true
            }
        }

        if needsMark {
            markDirty()
        }
    }

    func apply(_ policies: [CachePolicy]) {
        lock.lock(); defer { lock.unlock() }

        for policy in policies {
            switch policy {
            case .maxItemCount(let maxItemCount):
                if cache.count > maxItemCount {
                    // Evict LRU
                    let items = cache.values.sorted(by: { $0.lastAccessDate < $1.lastAccessDate })
                    let countToEvict = cache.count - maxItemCount
                    let keysToEvict = items.map({ $0.key })[0 ..< countToEvict]

                    if !keysToEvict.isEmpty {
                        config.delegate?.logDebugMessage(
                            "Max count of \(maxItemCount) exceeded, evicting \(countToEvict) items from cache."
                        )
                        keysToEvict.forEach { cache.removeValue(forKey: $0) }
                        markDirty()
                    }
                }

            case .maxItemLifetime(let timeInterval):
                let date = Date()
                let keysToEvict = cache.values
                    .filter { date.timeIntervalSince($0.creationDate) > timeInterval }
                    .map { $0.key }

                if !keysToEvict.isEmpty {
                    for key in keysToEvict {
                        config.delegate?.logDebugMessage("Max time exceeded, evicting \(key) from cache.")
                        cache.removeValue(forKey: key)
                    }
                    markDirty()
                }
            }
        }
    }
}
