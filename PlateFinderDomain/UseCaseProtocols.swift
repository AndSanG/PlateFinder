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

/// Timestamp dividing the conversation: the chat shows only searches newer
/// than the cutoff, while the full history stays in the store ("soft clear").
public protocol LoadChatCutoff: Sendable {
    func execute() async throws -> Date?
}

public protocol SaveChatCutoff: Sendable {
    func execute(_ date: Date) async throws
}
