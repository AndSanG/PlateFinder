import Foundation

/// Persists the conversation's session markers: the soft-clear cutoff
/// (searches at or before it stay in history but are hidden from the chat)
/// and the instant the user last left the app (drives the auto "new chat").
final class UserDefaultsChatSessionStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private let cutoffKey = "chat_cutoff"
    private let lastSessionEndKey = "last_session_end"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadCutoff() -> Date? {
        defaults.object(forKey: cutoffKey) as? Date
    }

    func saveCutoff(_ date: Date) {
        defaults.set(date, forKey: cutoffKey)
    }

    func loadLastSessionEnd() -> Date? {
        defaults.object(forKey: lastSessionEndKey) as? Date
    }

    func saveLastSessionEnd(_ date: Date) {
        defaults.set(date, forKey: lastSessionEndKey)
    }
}

struct ChatCutoffLoader: LoadChatCutoff {
    let store: UserDefaultsChatSessionStore
    func execute() async throws -> Date? { store.loadCutoff() }
}

struct ChatCutoffSaver: SaveChatCutoff {
    let store: UserDefaultsChatSessionStore
    func execute(_ date: Date) async throws { store.saveCutoff(date) }
}

struct LastSessionEndLoader: LoadLastSessionEnd {
    let store: UserDefaultsChatSessionStore
    func execute() async throws -> Date? { store.loadLastSessionEnd() }
}

struct LastSessionEndSaver: SaveLastSessionEnd {
    let store: UserDefaultsChatSessionStore
    func execute(_ date: Date) async throws { store.saveLastSessionEnd(date) }
}
