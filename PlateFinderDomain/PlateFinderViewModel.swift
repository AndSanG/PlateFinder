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

    public func loadHistory() async {
        history = (try? await store.retrieve()) ?? []
    }

    public func search() async {
        guard plateFormat == .car || plateFormat == .bike || plateFormat == .special else { return }
        error = nil
        result = nil
        let plate = plateText
        let car: Car?
        do {
            let loaded = try await loader.loadCarInfo(for: plate)
            result = loaded
            car = loaded
        } catch let e as CarInfoError {
            error = e
            car = nil
        } catch {
            self.error = .parsingError(error.localizedDescription)
            car = nil
        }
        let item = SearchHistoryItem(plateNumber: plate, searchDate: Date(), car: car)
        try? await store.insert(item)
        history = (try? await store.retrieve()) ?? history
    }
}
