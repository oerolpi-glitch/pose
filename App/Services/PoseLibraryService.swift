import Foundation
import PoseKit

protocol PoseLibraryProviding {
    func allPoses() -> [ReferencePose]
    func poses(matching query: String, tag: String?) -> [ReferencePose]
    func allTags() -> [String]
    func poses(in collection: IntentCollection) -> [ReferencePose]
}

/// Loads and searches the bundled reference pose library.
final class PoseLibraryService: PoseLibraryProviding {
    private let bundle: Bundle
    private lazy var cache: [ReferencePose] = load()

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func allPoses() -> [ReferencePose] { cache }

    func poses(matching query: String, tag: String?) -> [ReferencePose] {
        var result = cache
        if let tag { result = result.filter { $0.tags.contains(tag) } }
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            result = result.filter {
                $0.title.lowercased().contains(q) || $0.tags.contains { $0.lowercased().contains(q) }
            }
        }
        return result
    }

    func allTags() -> [String] {
        let priority = ["mirror", "close-up", "selfie"]
        let all = Set(cache.flatMap(\.tags))
        return priority.filter(all.contains) + all.subtracting(priority).sorted()
    }

    func poses(in collection: IntentCollection) -> [ReferencePose] {
        cache.filter { $0.collections.contains(collection.rawValue) }
    }

    private func load() -> [ReferencePose] {
        let urls = bundle.urls(forResourcesWithExtension: "json", subdirectory: "Poses") ?? []
        let decoder = JSONDecoder()
        return urls.compactMap { url in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? decoder.decode(ReferencePose.self, from: data)
        }.sorted { $0.title < $1.title }
    }
}
