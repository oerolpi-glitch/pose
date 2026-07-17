import Foundation
import Combine

protocol FavoritesStoring {
    func isFavorite(_ id: String) -> Bool
    func toggle(_ id: String)
}

/// UserDefaults-backed favorite pose IDs.
final class FavoritesStore: ObservableObject, FavoritesStoring {
    @Published private(set) var ids: Set<String>
    private let defaults: UserDefaults
    private static let key = "favoritePoseIDs"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        ids = Set(defaults.stringArray(forKey: Self.key) ?? [])
    }

    func isFavorite(_ id: String) -> Bool { ids.contains(id) }

    func toggle(_ id: String) {
        if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
        defaults.set(Array(ids), forKey: Self.key)
    }
}
