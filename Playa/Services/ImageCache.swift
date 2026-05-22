import SwiftUI
import UIKit

/// LRU memory cache for remote images, with a tiny disk fallback under
/// `Caches/playa-images/`. Keeps the feed scrolling smooth and lets profile
/// screens load instantly on re-entry.
final class ImageCache {
    static let shared = ImageCache()

    private let memory: NSCache<NSURL, UIImage>
    private let diskFolder: URL?
    private let fileManager = FileManager.default

    private init() {
        let cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 220
        cache.totalCostLimit = 96 * 1024 * 1024 // ~96MB in-memory ceiling
        self.memory = cache

        if let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let folder = caches.appendingPathComponent("playa-images", isDirectory: true)
            try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
            self.diskFolder = folder
        } else {
            self.diskFolder = nil
        }
    }

    // MARK: - Memory

    func image(for url: URL) -> UIImage? {
        if let cached = memory.object(forKey: url as NSURL) {
            return cached
        }
        if let disk = diskImage(for: url) {
            memory.setObject(disk, forKey: url as NSURL, cost: disk.estimatedCost)
            return disk
        }
        return nil
    }

    func store(_ image: UIImage, for url: URL) {
        memory.setObject(image, forKey: url as NSURL, cost: image.estimatedCost)
        storeOnDisk(image, for: url)
    }

    // MARK: - Disk

    private func diskURL(for url: URL) -> URL? {
        guard let folder = diskFolder else { return nil }
        let safeName = url.absoluteString.data(using: .utf8)?.base64EncodedString() ?? url.lastPathComponent
        return folder.appendingPathComponent(safeName).appendingPathExtension("img")
    }

    private func diskImage(for url: URL) -> UIImage? {
        guard let path = diskURL(for: url),
              let data = try? Data(contentsOf: path),
              let img = UIImage(data: data) else { return nil }
        return img
    }

    private func storeOnDisk(_ image: UIImage, for url: URL) {
        guard let path = diskURL(for: url) else { return }
        // 0.8 JPEG keeps file size sane while staying visually clean.
        let data = image.jpegData(compressionQuality: 0.82) ?? image.pngData()
        try? data?.write(to: path, options: .atomic)
    }

    // MARK: - Lifecycle

    /// Drops every cached image — call on sign-out so the next user starts clean.
    func clearAll() {
        memory.removeAllObjects()
        if let folder = diskFolder {
            try? fileManager.removeItem(at: folder)
            try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
    }
}

private extension UIImage {
    /// Rough byte cost (4 bytes per pixel) — used to bound the in-memory cache.
    var estimatedCost: Int {
        Int(size.width * size.height * scale * scale * 4)
    }
}

// MARK: - SwiftUI wrapper

/// Drop-in replacement for AsyncImage that consults `ImageCache.shared` first
/// and falls back to a network fetch. Renders a gradient placeholder while
/// loading or on failure, matching the POSTER v2 feel.
struct CachedAsyncImage: View {
    let url: URL?
    var contentMode: ContentMode = .fill

    @State private var loaded: UIImage?
    @State private var failed = false

    var body: some View {
        ZStack {
            if let img = loaded {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder
            }
        }
        .clipped()
        .task(id: url) {
            await load()
        }
    }

    private var placeholder: some View {
        LinearGradient(
            colors: [PlayaStyle.ink800, PlayaStyle.ink700, PlayaStyle.hotDeep.opacity(0.36)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func load() async {
        guard let url else { return }
        if let cached = ImageCache.shared.image(for: url) {
            loaded = cached
            return
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode,
                  let img = UIImage(data: data) else {
                failed = true
                return
            }
            ImageCache.shared.store(img, for: url)
            loaded = img
        } catch {
            failed = true
        }
    }
}
