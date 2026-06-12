import Testing
import Foundation
@testable import PlateFinderDomain

@MainActor
@Suite struct HistoryViewModelTests {

    @Test func init_setsLoadingState() {
        let (sut, _, _, _, _, _) = makeSUT()
        #expect(sut.state == .loading)
    }

    @Test func loadData_setsLoadedStateWithHistoryAndFavorites() async {
        let items = [makeHistoryItem("ABC1234"), makeHistoryItem("ZZZ9999")]
        let favorites = ["ABC1234"]
        let (sut, loadHistory, loadFavorites, _, _, _) = makeSUT()
        loadHistory.stubbedItems = items
        loadFavorites.stubbedFavorites = favorites

        await sut.loadData()

        #expect(sut.state == .loaded(history: items, favorites: favorites))
    }

    @Test func loadData_setsErrorStateOnFailure() async {
        let (sut, loadHistory, _, _, _, _) = makeSUT()
        loadHistory.shouldThrow = true

        await sut.loadData()

        if case .error = sut.state { } else {
            Issue.record("Expected .error state, got \(sut.state)")
        }
    }

    @Test func delete_removesItemFromLoadedHistory() async {
        let item = makeHistoryItem("ABC1234")
        let (sut, loadHistory, _, deleteFromHistory, _, _) = makeSUT()
        loadHistory.stubbedItems = [item]
        await sut.loadData()

        await sut.delete(item)

        #expect(deleteFromHistory.callCount == 1)
        if case .loaded(let history, _) = sut.state {
            #expect(!history.contains(item))
        } else {
            Issue.record("Expected .loaded state after delete")
        }
    }

    @Test func clearAll_emptiesHistory() async {
        let item = makeHistoryItem("ABC1234")
        let (sut, loadHistory, _, _, clearHistory, _) = makeSUT()
        loadHistory.stubbedItems = [item]
        await sut.loadData()

        await sut.clearAll()

        #expect(clearHistory.callCount == 1)
        if case .loaded(let history, _) = sut.state {
            #expect(history.isEmpty)
        } else {
            Issue.record("Expected .loaded state after clearAll")
        }
    }

    @Test func toggleFavorite_addsFavoriteWhenNotPresent() async {
        let (sut, _, _, _, _, toggleFavorite) = makeSUT()
        toggleFavorite.stubbedResult = ["ABC1234"]
        await sut.loadData()

        await sut.toggleFavorite("ABC1234")

        #expect(toggleFavorite.callCount == 1)
        if case .loaded(_, let favorites) = sut.state {
            #expect(favorites.contains("ABC1234"))
        } else {
            Issue.record("Expected .loaded state after toggleFavorite")
        }
    }

    @Test func toggleFavorite_removesFavoriteWhenAlreadyPresent() async {
        let (sut, _, loadFavorites, _, _, toggleFavorite) = makeSUT()
        loadFavorites.stubbedFavorites = ["ABC1234"]
        toggleFavorite.stubbedResult = []
        await sut.loadData()

        await sut.toggleFavorite("ABC1234")

        #expect(toggleFavorite.callCount == 1)
        if case .loaded(_, let favorites) = sut.state {
            #expect(!favorites.contains("ABC1234"))
        } else {
            Issue.record("Expected .loaded state after toggleFavorite")
        }
    }

    @Test func loadData_loadsChatCutoff() async {
        let cutoff = Date(timeIntervalSince1970: 1000)
        let loadChatCutoff = LoadChatCutoffSpy()
        loadChatCutoff.stubbedCutoff = cutoff
        let (sut, _, _, _, _, _) = makeSUT(loadChatCutoff: loadChatCutoff)

        await sut.loadData()

        #expect(sut.chatCutoff == cutoff)
    }

    @Test func clearChat_persistsAndSetsCutoff() async {
        let saveChatCutoff = SaveChatCutoffSpy()
        let (sut, _, _, _, _, _) = makeSUT(saveChatCutoff: saveChatCutoff)
        #expect(sut.chatCutoff == nil)

        await sut.clearChat()

        #expect(saveChatCutoff.savedDates.count == 1)
        #expect(sut.chatCutoff == saveChatCutoff.savedDates.first)
    }

    @Test func doesNotLeakAfterLoadData() async {
        let loadHistory = LoadHistorySpy()
        loadHistory.stubbedItems = [makeHistoryItem("ABC1234")]
        var sut: HistoryViewModel? = HistoryViewModel(
            loadHistory: loadHistory,
            loadFavorites: LoadFavoritesSpy(),
            deleteFromHistory: DeleteFromHistorySpy(),
            clearHistory: ClearHistorySpy(),
            toggleFavorite: ToggleFavoriteSpy(),
            loadChatCutoff: LoadChatCutoffSpy(),
            saveChatCutoff: SaveChatCutoffSpy()
        )
        weak var weakSUT = sut

        await sut!.loadData()
        sut = nil

        #expect(weakSUT == nil, "Potential memory leak — HistoryViewModel")
    }

    // MARK: - Helpers

    private func makeSUT(
        loadChatCutoff: LoadChatCutoffSpy = LoadChatCutoffSpy(),
        saveChatCutoff: SaveChatCutoffSpy = SaveChatCutoffSpy()
    ) -> (
        HistoryViewModel,
        LoadHistorySpy,
        LoadFavoritesSpy,
        DeleteFromHistorySpy,
        ClearHistorySpy,
        ToggleFavoriteSpy
    ) {
        let loadHistory = LoadHistorySpy()
        let loadFavorites = LoadFavoritesSpy()
        let deleteFromHistory = DeleteFromHistorySpy()
        let clearHistory = ClearHistorySpy()
        let toggleFavorite = ToggleFavoriteSpy()
        let sut = HistoryViewModel(
            loadHistory: loadHistory,
            loadFavorites: loadFavorites,
            deleteFromHistory: deleteFromHistory,
            clearHistory: clearHistory,
            toggleFavorite: toggleFavorite,
            loadChatCutoff: loadChatCutoff,
            saveChatCutoff: saveChatCutoff
        )
        return (sut, loadHistory, loadFavorites, deleteFromHistory, clearHistory, toggleFavorite)
    }

    private func makeHistoryItem(_ plate: String) -> SearchHistoryItem {
        SearchHistoryItem(plateNumber: plate, searchDate: Date(), car: nil)
    }
}

// MARK: - Test Doubles

private final class LoadHistorySpy: LoadHistory {
    var stubbedItems: [SearchHistoryItem] = []
    var shouldThrow = false

    func execute() async throws -> [SearchHistoryItem] {
        if shouldThrow { throw NSError(domain: "LoadHistorySpy", code: 0) }
        return stubbedItems
    }
}

private final class LoadFavoritesSpy: LoadFavorites {
    var stubbedFavorites: [String] = []
    var shouldThrow = false

    func execute() async throws -> [String] {
        if shouldThrow { throw NSError(domain: "LoadFavoritesSpy", code: 0) }
        return stubbedFavorites
    }
}

private final class DeleteFromHistorySpy: DeleteFromHistory {
    private(set) var callCount = 0

    func execute(_ item: SearchHistoryItem) async throws {
        callCount += 1
    }
}

private final class ClearHistorySpy: ClearHistory {
    private(set) var callCount = 0

    func execute() async throws {
        callCount += 1
    }
}

private final class ToggleFavoriteSpy: ToggleFavorite {
    private(set) var callCount = 0
    var stubbedResult: [String] = []

    func execute(plate: String) async throws -> [String] {
        callCount += 1
        return stubbedResult
    }
}

private final class LoadChatCutoffSpy: LoadChatCutoff {
    var stubbedCutoff: Date?

    func execute() async throws -> Date? { stubbedCutoff }
}

private final class SaveChatCutoffSpy: SaveChatCutoff {
    private(set) var savedDates: [Date] = []

    func execute(_ date: Date) async throws {
        savedDates.append(date)
    }
}
