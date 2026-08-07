import Foundation

final class UserDefaultsCarStore: CarStore, FavoritesStore, @unchecked Sendable {
    private let defaults: UserDefaults
    private let historyKey = "search_history"
    private let favoritesKey = "favorites"
    private let maxHistoryItems = 50

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: CarStore

    func retrieve() async throws -> [SearchHistoryItem] {
        guard let data = defaults.data(forKey: historyKey),
              let items = try? JSONDecoder().decode([SearchHistoryItem].self, from: data) else {
            return []
        }
        return items
    }

    func insert(_ item: SearchHistoryItem) async throws {
        var items = (try? await retrieve()) ?? []
        items.removeAll { $0.plateNumber == item.plateNumber }
        items.insert(item, at: 0)
        if items.count > maxHistoryItems { items = Array(items.prefix(maxHistoryItems)) }
        if let data = try? JSONEncoder().encode(items) { defaults.set(data, forKey: historyKey) }
    }

    func delete(_ item: SearchHistoryItem) async throws {
        var items = (try? await retrieve()) ?? []
        items.removeAll { $0.plateNumber == item.plateNumber }
        if let data = try? JSONEncoder().encode(items) { defaults.set(data, forKey: historyKey) }
    }

    func deleteAll() async throws {
        defaults.removeObject(forKey: historyKey)
    }

    // MARK: FavoritesStore

    func retrieveFavorites() async throws -> [String] {
        defaults.stringArray(forKey: favoritesKey) ?? []
    }

    func insertFavorite(_ plateNumber: String) async throws {
        var favs = (try? await retrieveFavorites()) ?? []
        if !favs.contains(plateNumber) {
            favs.append(plateNumber)
            defaults.set(favs, forKey: favoritesKey)
        }
    }

    func deleteFavorite(_ plateNumber: String) async throws {
        var favs = (try? await retrieveFavorites()) ?? []
        favs.removeAll { $0 == plateNumber }
        defaults.set(favs, forKey: favoritesKey)
    }
}
