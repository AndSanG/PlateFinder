import Foundation

struct HistoryLoader: LoadHistory {
    let store: any CarStore
    func execute() async throws -> [SearchHistoryItem] { try await store.retrieve() }
}

struct HistoryAdder: AddToHistory {
    let store: any CarStore
    func execute(_ item: SearchHistoryItem) async throws { try await store.insert(item) }
}

struct HistoryDeleter: DeleteFromHistory {
    let store: any CarStore
    func execute(_ item: SearchHistoryItem) async throws { try await store.delete(item) }
}

struct HistoryClearer: ClearHistory {
    let store: any CarStore
    func execute() async throws { try await store.deleteAll() }
}
