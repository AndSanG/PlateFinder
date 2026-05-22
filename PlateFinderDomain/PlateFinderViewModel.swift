import Observation

@Observable
@MainActor
public final class PlateFinderViewModel {
    public var plateText: String = ""
    public var isLoading: Bool = false
    public var result: Car? = nil
    public var error: CarInfoError? = nil
    public var history: [SearchHistoryItem] = []
    public var favorites: [String] = []

    public var plateFormat: PlateFormat {
        PlateValidator.validate(plateText)
    }

    private let loader: CarInfoLoader
    private let store: CarStore
    private let favoritesStore: FavoritesStore

    public init(loader: CarInfoLoader, store: CarStore, favoritesStore: FavoritesStore) {
        self.loader = loader
        self.store = store
        self.favoritesStore = favoritesStore
    }
}
