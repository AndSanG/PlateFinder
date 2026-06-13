import Foundation

/// Singleton that hands live ViewModels to the CarPlay scene delegate.
/// Populated in PlateFinderApp.init, which runs even for CarPlay-only launches.
@MainActor
final class CarPlayDependencyBridge {
    static let shared = CarPlayDependencyBridge()
    private init() {}

    var searchViewModel: SearchViewModel?
    var historyViewModel: HistoryViewModel?
    var intentRouter: IntentRouter?
}
