import Foundation
import Observation

@Observable
@MainActor
public final class HistoryViewModel {
    public private(set) var state: HistoryViewState = .loading
    /// Searches at or before this instant are hidden from the conversation
    /// (soft clear); they remain in the store and the history list.
    public private(set) var chatCutoff: Date?

    private let loadHistory: any LoadHistory
    private let loadFavorites: any LoadFavorites
    private let deleteFromHistory: any DeleteFromHistory
    private let clearHistory: any ClearHistory
    private let toggleFav: any ToggleFavorite
    private let loadChatCutoff: any LoadChatCutoff
    private let saveChatCutoff: any SaveChatCutoff
    private let loadLastSessionEnd: any LoadLastSessionEnd
    private let saveLastSessionEnd: any SaveLastSessionEnd
    private let sessionTimeout: TimeInterval

    public init(
        loadHistory: any LoadHistory,
        loadFavorites: any LoadFavorites,
        deleteFromHistory: any DeleteFromHistory,
        clearHistory: any ClearHistory,
        toggleFavorite: any ToggleFavorite,
        loadChatCutoff: any LoadChatCutoff,
        saveChatCutoff: any SaveChatCutoff,
        loadLastSessionEnd: any LoadLastSessionEnd,
        saveLastSessionEnd: any SaveLastSessionEnd,
        sessionTimeout: TimeInterval = 30 * 60
    ) {
        self.loadHistory = loadHistory
        self.loadFavorites = loadFavorites
        self.deleteFromHistory = deleteFromHistory
        self.clearHistory = clearHistory
        self.toggleFav = toggleFavorite
        self.loadChatCutoff = loadChatCutoff
        self.saveChatCutoff = saveChatCutoff
        self.loadLastSessionEnd = loadLastSessionEnd
        self.saveLastSessionEnd = saveLastSessionEnd
        self.sessionTimeout = sessionTimeout
    }

    public func loadData() async {
        do {
            let history = try await loadHistory.execute()
            let favorites = try await loadFavorites.execute()
            // The cutoff is cosmetic; failing to read it must not block the list.
            chatCutoff = (try? await loadChatCutoff.execute()) ?? nil
            state = .loaded(history: history, favorites: favorites)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    public func clearChat() async {
        let cutoff = Date()
        // Persistence is best-effort: the chat still clears for this session
        // even if the write fails.
        try? await saveChatCutoff.execute(cutoff)
        chatCutoff = cutoff
    }

    public func recordSessionEnd() async {
        try? await saveLastSessionEnd.execute(Date())
    }

    /// Auto "new chat" after a long absence, like messaging apps: soft-clears
    /// when the user returns past the session timeout. Returns whether it
    /// cleared, so callers can also reset transient screen state.
    @discardableResult
    public func clearChatIfExpired(now: Date = Date()) async -> Bool {
        guard let lastSeen = (try? await loadLastSessionEnd.execute()) ?? nil,
              now.timeIntervalSince(lastSeen) > sessionTimeout
        else { return false }
        await clearChat()
        return true
    }

    public func delete(_ item: SearchHistoryItem) async {
        guard case .loaded(let history, let favorites) = state else { return }
        do {
            try await deleteFromHistory.execute(item)
            state = .loaded(history: history.filter { $0 != item }, favorites: favorites)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    public func clearAll() async {
        do {
            try await clearHistory.execute()
            if case .loaded(_, let favorites) = state {
                state = .loaded(history: [], favorites: favorites)
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    public func toggleFavorite(_ plate: String) async {
        guard case .loaded(let history, _) = state else { return }
        do {
            let newFavorites = try await toggleFav.execute(plate: plate)
            state = .loaded(history: history, favorites: newFavorites)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
