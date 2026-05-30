public enum SearchViewState: Equatable {
    case idle
    case loading
    case success(Car)
    case error(String)
}

public enum HistoryViewState: Equatable {
    case loading
    case loaded(history: [SearchHistoryItem], favorites: [String])
    case error(String)
}
