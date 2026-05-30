import Foundation

public protocol LoadHistory: Sendable {
    func execute() async throws -> [SearchHistoryItem]
}

public protocol AddToHistory: Sendable {
    func execute(_ item: SearchHistoryItem) async throws
}

public protocol DeleteFromHistory: Sendable {
    func execute(_ item: SearchHistoryItem) async throws
}

public protocol ClearHistory: Sendable {
    func execute() async throws
}

public protocol LoadFavorites: Sendable {
    func execute() async throws -> [String]
}

public protocol ToggleFavorite: Sendable {
    func execute(plate: String) async throws -> [String]
}
