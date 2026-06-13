import Testing
import Foundation
@testable import PlateFinderDomain

@MainActor
@Suite struct IntentSearchCoordinatorTests {

    @Test func start_dispatchesSearchWhenPendingPlateArrives() async throws {
        let (sut, router, loader) = makeSUT()
        sut.start()
        await Task.yield()          // Let the loop reach withObservationTracking

        router.requestSearch(plate: "ABC1234")
        try await Task.sleep(for: .milliseconds(50))

        #expect(loader.callCount == 1)
        #expect(loader.loadedPlates == ["ABC1234"])
    }

    @Test func start_consumesPendingPlateAfterDispatch() async throws {
        let (sut, router, _) = makeSUT()
        sut.start()
        await Task.yield()

        router.requestSearch(plate: "ABC1234")
        try await Task.sleep(for: .milliseconds(50))

        #expect(router.pendingPlate == nil)
    }

    @Test func start_setsLastRequestWithFreshUUID() async throws {
        let (sut, router, _) = makeSUT()
        sut.start()
        await Task.yield()

        router.requestSearch(plate: "ABC1234")
        try await Task.sleep(for: .milliseconds(50))

        #expect(sut.lastRequest?.plate == "ABC1234")
        #expect(sut.lastRequest?.id != nil)
    }

    @Test func start_assignsDistinctUUIDPerRequest() async throws {
        let (sut, router, loader) = makeSUT()
        loader.stubbedResult = .success(makeCar())
        sut.start()
        await Task.yield()

        router.requestSearch(plate: "ABC1234")
        try await Task.sleep(for: .milliseconds(50))
        let firstID = sut.lastRequest?.id

        router.requestSearch(plate: "ZZZ9999")
        try await Task.sleep(for: .milliseconds(50))

        #expect(sut.lastRequest?.plate == "ZZZ9999")
        #expect(sut.lastRequest?.id != firstID)
    }

    // MARK: - Helpers

    private func makeSUT() -> (IntentSearchCoordinator, IntentRouter, LoadCarInfoSpy) {
        let router = IntentRouter()
        let loader = LoadCarInfoSpy()
        let vm = SearchViewModel(loadCarInfo: loader, addToHistory: AddToHistorySpy())
        let sut = IntentSearchCoordinator(intentRouter: router, searchViewModel: vm)
        return (sut, router, loader)
    }

    private func makeCar() -> Car {
        Car(
            plate: "ABC1234", manufacturer: "TOYOTA", colorName: "WHITE",
            registrationYear: "2020", model: "COROLLA", segment: "SEDAN",
            registrationDate: "01-01-2020", year: "2019", service: "PRIVATE",
            expirationDate: "01-01-2025", tint: "NONE", tintExpirationDate: ""
        )
    }
}

// MARK: - Test Doubles

private final class LoadCarInfoSpy: LoadCarInfo {
    var callCount = 0
    var loadedPlates: [String] = []
    var stubbedResult: Result<Car, Error> = .failure(NSError(domain: "LoadCarInfoSpy", code: 0))

    func execute(plate: String) async throws -> Car {
        callCount += 1
        loadedPlates.append(plate)
        return try stubbedResult.get()
    }
}

private final class AddToHistorySpy: AddToHistory {
    func execute(_ item: SearchHistoryItem) async throws {}
}
