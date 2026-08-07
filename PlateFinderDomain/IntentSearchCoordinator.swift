import Foundation
import Observation

/// Owns the dispatch of pending Siri / App Intent searches.
/// A `withObservationTracking` re-arm loop watches `IntentRouter.pendingPlate`
/// so it works even when the CarPlay scene is the only active scene.
@Observable
@MainActor
public final class IntentSearchCoordinator {
    public struct Request: Equatable {
        public let id: UUID
        public let plate: String
    }

    public private(set) var lastRequest: Request?

    private let intentRouter: IntentRouter
    private let searchViewModel: SearchViewModel

    public init(intentRouter: IntentRouter, searchViewModel: SearchViewModel) {
        self.intentRouter = intentRouter
        self.searchViewModel = searchViewModel
    }

    public func start() {
        Task { [weak self] in
            await self?.loop()
        }
    }

    private func loop() async {
        while !Task.isCancelled {
            await waitForChange()
            guard let plate = intentRouter.pendingPlate else { continue }
            intentRouter.consume()
            lastRequest = Request(id: UUID(), plate: plate)
            await searchViewModel.search(plate: plate)
        }
    }

    private func waitForChange() async {
        // UnsafeContinuation: won't fatal-error if the coordinator is freed
        // before the observation fires (e.g. in tests or when the scene goes away).
        await withUnsafeContinuation { (continuation: UnsafeContinuation<Void, Never>) in
            withObservationTracking {
                _ = intentRouter.pendingPlate
            } onChange: {
                continuation.resume()
            }
        }
    }
}
