import AppIntents
import SwiftUI

struct PlateEntity: AppEntity {
    let id: String
    let plateNumber: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(plateNumber)")
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "License Plate")
    }

    static var defaultQuery = PlateEntityQuery()
}

struct PlateEntityQuery: EntityQuery {
    func entities(for identifiers: [PlateEntity.ID]) async throws -> [PlateEntity] {
        identifiers.map { PlateEntity(id: $0, plateNumber: $0) }
    }

    func suggestedEntities() async throws -> [PlateEntity] {
        [
            PlateEntity(id: "ABC1234", plateNumber: "ABC1234"),
            PlateEntity(id: "XYZ5678", plateNumber: "XYZ5678")
        ]
    }

    func entities(matching string: String) async throws -> [PlateEntity] {
        let cleaned = string.uppercased().replacingOccurrences(of: " ", with: "")
        let format = PlateValidator.validate(cleaned)
        guard format != .invalid && format != .empty else { return [] }
        return [PlateEntity(id: cleaned, plateNumber: cleaned)]
    }
}

struct FindPlateIntent: AppIntent {
    static var title: LocalizedStringResource = "Find Plate"
    static var description = IntentDescription("Search for a license plate")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Plate Number")
    var plateNumber: PlateEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        let plateText = plateNumber.plateNumber.uppercased()
        let format = PlateValidator.validate(plateText)
        guard format == .car || format == .bike || format == .special else {
            throw $plateNumber.needsValueError("Please provide a valid license plate number in format ABC1234")
        }
        // UserDefaults survives across process boundaries; the app reads it on activation.
        // The in-process bridge is kept as a fast path for when the app is already running.
        UserDefaults.standard.set(plateText, forKey: "pendingIntentPlate")
        AppIntentIntentRouterBridge.shared.requestSearch(plate: plateText)
        return .result(dialog: "Searching for license plate \(plateText) in PlateFinder")
    }
}

enum PlateFinderShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: FindPlateIntent(),
            phrases: [
                "Find plate \(\.$plateNumber) in \(.applicationName)",
                "Search plate \(\.$plateNumber) in \(.applicationName)",
                "Look up plate \(\.$plateNumber) in \(.applicationName)",
                "Find license plate \(\.$plateNumber) in \(.applicationName)",
                "Search for \(\.$plateNumber) in \(.applicationName)",
                "Look up \(\.$plateNumber) in \(.applicationName)"
            ],
            shortTitle: "Find Plate",
            systemImageName: "magnifyingglass.circle"
        )
    }
}

// Bridge: AppIntents run in their own process and cannot directly access the SwiftUI
// environment. This wrapper holds a weak reference to the IntentRouter that the
// composition root registers at launch.
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
