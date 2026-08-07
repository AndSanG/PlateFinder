import Foundation

struct FavoritesLoader: LoadFavorites {
    let store: any FavoritesStore
    func execute() async throws -> [String] { try await store.retrieveFavorites() }
}

struct FavoritesToggler: ToggleFavorite {
    let store: any FavoritesStore
    func execute(plate: String) async throws -> [String] {
        var favs = try await store.retrieveFavorites()
        if favs.contains(plate) {
            try await store.deleteFavorite(plate)
            favs.removeAll { $0 == plate }
        } else {
            try await store.insertFavorite(plate)
            favs.append(plate)
        }
        return favs
    }
}
