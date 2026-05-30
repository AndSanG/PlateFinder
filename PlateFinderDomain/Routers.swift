import Foundation
import Observation

@Observable
@MainActor
public final class IntentRouter {
    public private(set) var pendingPlate: String?

    public init() {}

    public func requestSearch(plate: String) {
        pendingPlate = plate
    }

    public func consume() {
        pendingPlate = nil
    }
}

@Observable
@MainActor
public final class AppRouter {
    public enum Tab { case search, history }
    public var selectedTab: Tab = .search

    public init() {}
}
