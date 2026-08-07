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

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let plateText = plateNumber.plateNumber
            .uppercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()

        guard !plateText.isEmpty else {
            return .result(dialog: IntentDialog(stringLiteral: NSLocalizedString("siri_invalid_plate", comment: "")))
        }

        await MainActor.run {
            AppIntentIntentRouterBridge.shared.requestSearch(plate: plateText)
        }

        let isValid = PlateValidator.validate(plateText).isComplete
        if isValid {
            return .result(dialog: IntentDialog(stringLiteral: NSLocalizedString("siri_searching_plate", comment: "")))
        } else {
            return .result(dialog: IntentDialog(stringLiteral: NSLocalizedString("siri_invalid_plate", comment: "")))
        }
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

// Bridge between AppIntents and the injected IntentRouter. AppIntents constructs
// FindPlateIntent itself, so there is no constructor to inject through; the
// Composition Root pushes the router in during App.init. See the entry-point
// exception in architecture.md.
//
// `openAppWhenRun` makes perform() run in the app's process, so the router is
// normally already set. It can still be nil when a cold launch races the intent,
// hence the buffered plate: it replays as soon as the router lands.
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
