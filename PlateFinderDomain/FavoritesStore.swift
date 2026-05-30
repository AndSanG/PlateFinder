public protocol FavoritesStore: Sendable {
    func retrieveFavorites() async throws -> [String]
    func insertFavorite(_ plateNumber: String) async throws
    func deleteFavorite(_ plateNumber: String) async throws
}
