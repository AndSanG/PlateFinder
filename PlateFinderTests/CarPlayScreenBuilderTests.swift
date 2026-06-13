import Testing
import Foundation
@testable import PlateFinderDomain

@Suite struct CarPlayScreenBuilderTests {

    @Test func build_withIdleAndNoHistory_returnsEmptyRecentSearches() {
        let screen = CarPlayScreenBuilder.build(state: .idle, lastPlate: "", history: [])
        #expect(screen == .recentSearches([]))
    }

    @Test func build_withIdleAndHistory_deduplicatesRows() {
        let history: [SearchHistoryItem] = [
            .init(plateNumber: "ABC1234", searchDate: Date(), car: nil),
            .init(plateNumber: "ABC1234", searchDate: Date(), car: nil),
            .init(plateNumber: "ZZZ9999", searchDate: Date(), car: nil),
        ]
        let screen = CarPlayScreenBuilder.build(state: .idle, lastPlate: "", history: history)
        guard case .recentSearches(let rows) = screen else {
            Issue.record("Expected recentSearches"); return
        }
        #expect(rows.count == 2)
        #expect(rows[0].plate == "ABC1234")
        #expect(rows[1].plate == "ZZZ9999")
    }

    @Test func build_withIdleAndLargeHistory_capsAtTen() {
        let history = (1...15).map { i in
            SearchHistoryItem(plateNumber: "AB\(String(format: "%04d", i))A", searchDate: Date(), car: nil)
        }
        let screen = CarPlayScreenBuilder.build(state: .idle, lastPlate: "", history: history)
        guard case .recentSearches(let rows) = screen else {
            Issue.record("Expected recentSearches"); return
        }
        #expect(rows.count == 10)
    }

    @Test func build_withHistoryContainingCar_includesSubtitle() {
        let car = makeCar()
        let history = [SearchHistoryItem(plateNumber: "ABC1234", searchDate: Date(), car: car)]
        let screen = CarPlayScreenBuilder.build(state: .idle, lastPlate: "", history: history)
        guard case .recentSearches(let rows) = screen else {
            Issue.record("Expected recentSearches"); return
        }
        #expect(rows.first?.subtitle == "TOYOTA COROLLA")
    }

    @Test func build_withHistoryMissingCar_hasNilSubtitle() {
        let history = [SearchHistoryItem(plateNumber: "ABC1234", searchDate: Date(), car: nil)]
        let screen = CarPlayScreenBuilder.build(state: .idle, lastPlate: "", history: history)
        guard case .recentSearches(let rows) = screen else {
            Issue.record("Expected recentSearches"); return
        }
        #expect(rows.first?.subtitle == nil)
    }

    @Test func build_withLoadingState_returnsLoadingWithLastPlate() {
        let screen = CarPlayScreenBuilder.build(state: .loading, lastPlate: "ABC1234", history: [])
        #expect(screen == .loading(plate: "ABC1234"))
    }

    @Test func build_withSuccessState_returnsResultWithThreeDetailRows() {
        let screen = CarPlayScreenBuilder.build(state: .success(makeCar()), lastPlate: "ABC1234", history: [])
        guard case .result(let title, let detailRows) = screen else {
            Issue.record("Expected result, got \(screen)"); return
        }
        #expect(title == "TOYOTA COROLLA 2019")
        #expect(detailRows.count == 3)
        #expect(detailRows[0].labelKey == "color")
        #expect(detailRows[0].value == "WHITE")
        #expect(detailRows[1].labelKey == "usage")
        #expect(detailRows[2].labelKey == "registration_validity")
    }

    @Test func build_withErrorState_returnsErrorWithSameKey() {
        let screen = CarPlayScreenBuilder.build(state: .error("network_error"), lastPlate: "", history: [])
        #expect(screen == .error(messageKey: "network_error"))
    }

    // MARK: - Helpers

    private func makeCar() -> Car {
        Car(
            plate: "ABC1234", manufacturer: "TOYOTA", colorName: "WHITE",
            registrationYear: "2020", model: "COROLLA", segment: "SEDAN",
            registrationDate: "01-01-2020", year: "2019", service: "PRIVATE",
            expirationDate: "01-01-2025", tint: "NONE", tintExpirationDate: ""
        )
    }
}
