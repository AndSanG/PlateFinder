import AppIntents
import SwiftUI

struct PlateEntity: AppEntity, Sendable {
    let id: String
    let plateNumber: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(plateNumber)")
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "License Plate")
    }

    nonisolated(unsafe) static var defaultQuery = PlateEntityQuery()
}

struct PlateEntityQuery: EntityQuery, EntityStringQuery {
    func entities(for identifiers: [PlateEntity.ID]) -> [PlateEntity] {
        identifiers.map { id in
            PlateEntity(id: id, plateNumber: id)
        }
    }

    func suggestedEntities() -> [PlateEntity] {
        // Load recent searches from UserDefaults
        guard let data = UserDefaults.standard.data(forKey: "search_history"),
              let items = try? JSONDecoder().decode([SearchHistoryItem].self, from: data) else {
            return []
        }

        // Return most recent 10 unique plates
        var seen = Set<String>()
        return items.prefix(10).compactMap { item in
            let plate = item.plateNumber
            guard !seen.contains(plate) else { return nil }
            seen.insert(plate)
            return PlateEntity(id: plate, plateNumber: plate)
        }
    }

    func entities(matching string: String) -> [PlateEntity] {
        let cleaned = string.uppercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
        guard !cleaned.isEmpty else { return [] }
        return [PlateEntity(id: cleaned, plateNumber: cleaned)]
    }
}

struct FindPlateIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Find Plate"
    nonisolated(unsafe) static var description = IntentDescription("Search for a license plate")
    nonisolated(unsafe) static var openAppWhenRun: Bool = true

    @Parameter(title: "Plate Number", description: "Any license plate to search for")
    var plateNumber: PlateEntity

    func perform() async throws -> some IntentResult {
        let plateText = plateNumber.plateNumber
            .uppercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
        if !plateText.isEmpty {
            UserDefaults.standard.set(plateText, forKey: "pendingIntentPlate")
            await MainActor.run {
                AppIntentIntentRouterBridge.shared.requestSearch(plate: plateText)
            }
        }
        return .result()
    }
}

enum PlateFinderShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: FindPlateIntent(),
            phrases: [
                "Search for \(\.$plateNumber) in \(.applicationName)",
                "Look up \(\.$plateNumber) in \(.applicationName)",
                "Find \(\.$plateNumber) in \(.applicationName)",
                "Check \(\.$plateNumber) in \(.applicationName)"
            ],
            shortTitle: "Find Plate",
            systemImageName: "magnifyingglass.circle"
        )
    }
}

// Bridge: used as a fast path when the app is already running in-process.
// perform() no longer calls this — UserDefaults is the reliable cross-process channel.
@MainActor
final class AppIntentIntentRouterBridge {
    static let shared = AppIntentIntentRouterBridge()
    private init() {}

    private var bufferedPlate: String?

    weak var router: IntentRouter? {
        didSet {
            guard let plate = bufferedPlate else { return }
            router?.requestSearch(plate: plate)
            bufferedPlate = nil
        }
    }

    func requestSearch(plate: String) {
        guard let router else {
            bufferedPlate = plate
            return
        }
        router.requestSearch(plate: plate)
    }
}
