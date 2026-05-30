import Foundation
import Observation

@Observable
@MainActor
public final class HistoryViewModel {
    public private(set) var state: HistoryViewState = .loading

    private let loadHistory: any LoadHistory
    private let loadFavorites: any LoadFavorites
    private let deleteFromHistory: any DeleteFromHistory
    private let clearHistory: any ClearHistory
    private let toggleFav: any ToggleFavorite

    public init(
        loadHistory: any LoadHistory,
        loadFavorites: any LoadFavorites,
        deleteFromHistory: any DeleteFromHistory,
        clearHistory: any ClearHistory,
        toggleFavorite: any ToggleFavorite
    ) {
        self.loadHistory = loadHistory
        self.loadFavorites = loadFavorites
        self.deleteFromHistory = deleteFromHistory
        self.clearHistory = clearHistory
        self.toggleFav = toggleFavorite
    }

    public func loadData() async {
        do {
            let history = try await loadHistory.execute()
            let favorites = try await loadFavorites.execute()
            state = .loaded(history: history, favorites: favorites)
        } catch {
            state = .error(error.localizedDescription)
        }
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
