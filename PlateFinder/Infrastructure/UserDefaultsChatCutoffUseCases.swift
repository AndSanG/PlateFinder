import Foundation

/// Persists the conversation's soft-clear cutoff. Searches at or before the
/// cutoff stay in history but are hidden from the chat.
final class UserDefaultsChatCutoffStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "chat_cutoff"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> Date? {
        defaults.object(forKey: key) as? Date
    }

    func save(_ date: Date) {
        defaults.set(date, forKey: key)
    }
}

struct ChatCutoffLoader: LoadChatCutoff {
    let store: UserDefaultsChatCutoffStore
    func execute() async throws -> Date? { store.load() }
}

struct ChatCutoffSaver: SaveChatCutoff {
    let store: UserDefaultsChatCutoffStore
    func execute(_ date: Date) async throws { store.save(date) }
}
