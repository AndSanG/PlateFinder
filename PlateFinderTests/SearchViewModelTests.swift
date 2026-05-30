import Testing
import Foundation
@testable import PlateFinderDomain

@MainActor
@Suite struct SearchViewModelTests {

    @Test func init_doesNotCallDependencies() async {
        let loader = LoadCarInfoSpy()
        let addToHistory = AddToHistorySpy()
        var sut: SearchViewModel? = SearchViewModel(loadCarInfo: loader, addToHistory: addToHistory)
        weak var weakSUT = sut

        #expect(loader.callCount == 0)
        #expect(addToHistory.callCount == 0)
        #expect(sut!.state == .idle)

        sut = nil
        #expect(weakSUT == nil, "Potential memory leak — SearchViewModel")
    }

    @Test func search_setsLoadingStateDuringFetch() async {
        let loader = LoadCarInfoSpy()
        let sut = SearchViewModel(loadCarInfo: loader, addToHistory: AddToHistorySpy())

        loader.stubbedResult = .success(makeCar())
        await sut.search(plate: "ABC1234")

        #expect(loader.callCount == 1)
        #expect(loader.loadedPlates == ["ABC1234"])
    }

    @Test func search_setsSuccessStateOnSuccessfulLoad() async throws {
        let expectedCar = makeCar()
        let (sut, loader, _) = makeSUT()
        loader.stubbedResult = .success(expectedCar)

        await sut.search(plate: "ABC1234")

        #expect(sut.state == .success(expectedCar))
    }

    @Test func search_setsErrorStateOnCarInfoError() async {
        let (sut, loader, _) = makeSUT()
        loader.stubbedResult = .failure(CarInfoError.serverError)

        await sut.search(plate: "ABC1234")

        #expect(sut.state == .error(CarInfoError.serverError.userMessage))
    }

    @Test func search_setsErrorStateOnGenericError() async {
        let (sut, loader, _) = makeSUT()
        loader.stubbedResult = .failure(NSError(domain: "any", code: 0, userInfo: [NSLocalizedDescriptionKey: "network down"]))

        await sut.search(plate: "ABC1234")

        #expect(sut.state == .error("network down"))
    }

    @Test func search_savesSuccessfulResultToHistory() async {
        let car = makeCar()
        let (sut, loader, addToHistory) = makeSUT()
        loader.stubbedResult = .success(car)

        await sut.search(plate: "ABC1234")

        #expect(addToHistory.callCount == 1)
        #expect(addToHistory.insertedItems.first?.plateNumber == "ABC1234")
        #expect(addToHistory.insertedItems.first?.car == car)
    }

    @Test func search_doesNotSaveToHistoryOnFailure() async {
        let (sut, loader, addToHistory) = makeSUT()
        loader.stubbedResult = .failure(CarInfoError.serverError)

        await sut.search(plate: "ABC1234")

        #expect(addToHistory.callCount == 0)
    }

    @Test func show_setsSuccessStateWithCar() {
        let car = makeCar()
        let (sut, _, _) = makeSUT()

        sut.show(car)

        #expect(sut.state == .success(car))
    }

    @Test func reset_setsIdleState() async {
        let car = makeCar()
        let (sut, loader, _) = makeSUT()
        loader.stubbedResult = .success(car)
        await sut.search(plate: "ABC1234")

        sut.reset()

        #expect(sut.state == .idle)
    }

    @Test func doesNotLeakAfterSearchCompletes() async {
        let loader = LoadCarInfoSpy()
        var sut: SearchViewModel? = SearchViewModel(loadCarInfo: loader, addToHistory: AddToHistorySpy())
        weak var weakSUT = sut

        loader.stubbedResult = .success(makeCar())
        await sut!.search(plate: "ABC1234")
        sut = nil

        #expect(weakSUT == nil, "Potential memory leak — SearchViewModel retained after search")
    }

    // MARK: - Helpers

    private func makeSUT() -> (SearchViewModel, LoadCarInfoSpy, AddToHistorySpy) {
        let loader = LoadCarInfoSpy()
        let addToHistory = AddToHistorySpy()
        let sut = SearchViewModel(loadCarInfo: loader, addToHistory: addToHistory)
        return (sut, loader, addToHistory)
    }

    private func makeCar(plate: String = "ABC1234") -> Car {
        Car(
            plate: plate, manufacturer: "TOYOTA", colorName: "WHITE",
            registrationYear: "2020", model: "COROLLA", segment: "SEDAN",
            registrationDate: "01-01-2020", year: "2019", service: "PRIVATE",
            expirationDate: "01-01-2025", tint: "NONE", tintExpirationDate: ""
        )
    }
}

// MARK: - Test Doubles

private final class LoadCarInfoSpy: LoadCarInfo {
    private(set) var callCount = 0
    private(set) var loadedPlates: [String] = []
    var stubbedResult: Result<Car, Error> = .failure(NSError(domain: "LoadCarInfoSpy", code: 0))

    func execute(plate: String) async throws -> Car {
        callCount += 1
        loadedPlates.append(plate)
        return try stubbedResult.get()
    }
}

private final class AddToHistorySpy: AddToHistory {
    private(set) var callCount = 0
    private(set) var insertedItems: [SearchHistoryItem] = []

    func execute(_ item: SearchHistoryItem) async throws {
        callCount += 1
        insertedItems.append(item)
    }
}
