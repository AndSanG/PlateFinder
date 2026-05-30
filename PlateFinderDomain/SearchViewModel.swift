import Foundation
import Observation

@Observable
@MainActor
public final class SearchViewModel {
    public private(set) var state: SearchViewState = .idle

    private let loadCarInfo: any LoadCarInfo
    private let addToHistory: any AddToHistory

    public init(loadCarInfo: any LoadCarInfo, addToHistory: any AddToHistory) {
        self.loadCarInfo = loadCarInfo
        self.addToHistory = addToHistory
    }

    public func search(plate: String) async {
        state = .loading
        do {
            let car = try await loadCarInfo.execute(plate: plate)
            // History write is non-fatal: a successful lookup must reach the user
            // even if persistence fails.
            try? await addToHistory.execute(SearchHistoryItem(plateNumber: plate, searchDate: Date(), car: car))
            state = .success(car)
        } catch let e as CarInfoError {
            state = .error(e.userMessage)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    public func show(_ car: Car) {
        state = .success(car)
    }

    public func reset() {
        state = .idle
    }
}
