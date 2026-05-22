import Testing
import Foundation
@testable import PlateFinder

@MainActor
@Suite struct PlateFinderViewModelTests {

    @Test func search_savesSuccessfulResultToStore() async {
        let car = makeCar()
        let (sut, loader, store, _) = makeSUT()
        loader.stubbedResult = .success(car)
        sut.plateText = "ABC1234"
        await sut.search()
        #expect(store.insertCallCount == 1)
        #expect(store.insertedItems.first?.plateNumber == "ABC1234")
        #expect(store.insertedItems.first?.car == car)
    }

    @Test func search_savesFailedSearchToStoreWithNilCar() async {
        let (sut, loader, store, _) = makeSUT()
        loader.stubbedResult = .failure(CarInfoError.serverError)
        sut.plateText = "ABC1234"
        await sut.search()
        #expect(store.insertCallCount == 1)
        #expect(store.insertedItems.first?.plateNumber == "ABC1234")
        #expect(store.insertedItems.first?.car == nil)
    }

    @Test func search_setsResultOnSuccessfulLoad() async throws {
        let expectedCar = makeCar()
        let (sut, loader, _, _) = makeSUT()
        loader.stubbedResult = .success(expectedCar)
        sut.plateText = "ABC1234"
        await sut.search()
        #expect(sut.result == expectedCar)
        #expect(sut.error == nil)
    }

    @Test func search_setsErrorOnFailure() async {
        let (sut, loader, _, _) = makeSUT()
        loader.stubbedResult = .failure(CarInfoError.serverError)
        sut.plateText = "ABC1234"
        await sut.search()
        #expect(sut.error == .serverError)
        #expect(sut.result == nil)
    }

    @Test func search_callsLoaderWithCurrentPlateText() async {
        let (sut, loader, _, _) = makeSUT()
        sut.plateText = "ABC1234"
        await sut.search()
        #expect(loader.loadedPlates == ["ABC1234"])
    }

    @Test(arguments: ["", "ABC", "1INVALID"])
    func search_doesNotCallLoaderForNonCompletePlate(plate: String) async {
        let (sut, loader, _, _) = makeSUT()
        sut.plateText = plate
        await sut.search()
        #expect(loader.loadCallCount == 0)
    }

    @Test func plateFormat_tracksPlateText() {
        let (sut, _, _, _) = makeSUT()
        #expect(sut.plateFormat == .empty)
        sut.plateText = "ABC"
        #expect(sut.plateFormat == .partiallyValid)
        sut.plateText = "ABC1234"
        #expect(sut.plateFormat == .car)
        sut.plateText = "1INVALID"
        #expect(sut.plateFormat == .invalid)
    }

    @Test func init_doesNotCallLoaderOrStore() async {
        let loader = CarInfoLoaderSpy()
        let store = CarStoreSpy()
        let favStore = FavoritesStoreSpy()
        var sut: PlateFinderViewModel? = PlateFinderViewModel(loader: loader, store: store, favoritesStore: favStore)
        weak var weakSUT = sut

        #expect(loader.loadCallCount == 0)
        #expect(store.insertCallCount == 0)
        #expect(store.retrieveCallCount == 0)

        sut = nil
        #expect(weakSUT == nil, "Potential memory leak — PlateFinderViewModel")
    }
}

// MARK: - Test Doubles

private final class CarInfoLoaderSpy: CarInfoLoader {
    private(set) var loadCallCount = 0
    private(set) var loadedPlates: [String] = []
    var stubbedResult: Result<Car, Error> = .failure(NSError(domain: "CarInfoLoaderSpy", code: 0))

    func loadCarInfo(for plateNumber: String) async throws -> Car {
        loadCallCount += 1
        loadedPlates.append(plateNumber)
        return try stubbedResult.get()
    }
}

private final class CarStoreSpy: CarStore {
    private(set) var insertCallCount = 0
    private(set) var retrieveCallCount = 0
    private(set) var deleteCallCount = 0
    private(set) var deleteAllCallCount = 0
    private(set) var insertedItems: [SearchHistoryItem] = []
    var stubbedItems: [SearchHistoryItem] = []

    func retrieve() async throws -> [SearchHistoryItem] {
        retrieveCallCount += 1
        return stubbedItems
    }
    func insert(_ item: SearchHistoryItem) async throws {
        insertCallCount += 1
        insertedItems.append(item)
        stubbedItems.insert(item, at: 0)
    }
    func delete(_ item: SearchHistoryItem) async throws {
        deleteCallCount += 1
        stubbedItems.removeAll { $0 == item }
    }
    func deleteAll() async throws {
        deleteAllCallCount += 1
        stubbedItems = []
    }
}

private final class FavoritesStoreSpy: FavoritesStore {
    private(set) var insertCallCount = 0
    private(set) var deleteCallCount = 0
    private(set) var retrieveCallCount = 0
    var stubbedFavorites: [String] = []

    func retrieveFavorites() async throws -> [String] {
        retrieveCallCount += 1
        return stubbedFavorites
    }
    func insertFavorite(_ plateNumber: String) async throws {
        insertCallCount += 1
        stubbedFavorites.append(plateNumber)
    }
    func deleteFavorite(_ plateNumber: String) async throws {
        deleteCallCount += 1
        stubbedFavorites.removeAll { $0 == plateNumber }
    }
}

// MARK: - Shared helpers

@MainActor private func makeSUT(
    loader: CarInfoLoaderSpy = CarInfoLoaderSpy(),
    store: CarStoreSpy = CarStoreSpy(),
    favoritesStore: FavoritesStoreSpy = FavoritesStoreSpy()
) -> (PlateFinderViewModel, CarInfoLoaderSpy, CarStoreSpy, FavoritesStoreSpy) {
    let sut = PlateFinderViewModel(loader: loader, store: store, favoritesStore: favoritesStore)
    return (sut, loader, store, favoritesStore)
}

private func makeCar(plate: String = "ABC1234") -> Car {
    Car(plate: plate, manufacturer: "TOYOTA", colorName: "WHITE",
        registrationYear: "2020", model: "COROLLA", segment: "SEDAN",
        registrationDate: "01-01-2020", year: "2019", service: "PRIVATE",
        expirationDate: "01-01-2025", tint: "NONE", tintExpirationDate: "")
}
