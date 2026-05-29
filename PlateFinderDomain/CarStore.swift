public protocol CarStore {
    func retrieve() async throws -> [SearchHistoryItem]
    func insert(_ item: SearchHistoryItem) async throws
    func delete(_ item: SearchHistoryItem) async throws
    func deleteAll() async throws
}
