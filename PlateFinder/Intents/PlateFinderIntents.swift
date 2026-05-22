
import AppIntents
import SwiftUI

// Custom AppEntity for plate numbers
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
        return identifiers.map { PlateEntity(id: $0, plateNumber: $0) }
    }
    
    func suggestedEntities() async throws -> [PlateEntity] {
        // Provide some example plate formats to help Siri understand
        return [
            PlateEntity(id: "ABC1234", plateNumber: "ABC1234"),
            PlateEntity(id: "XYZ5678", plateNumber: "XYZ5678")
        ]
    }
    
    func entities(matching string: String) async throws -> [PlateEntity] {
        // Clean and validate the input string
        let cleanedString = string.uppercased().replacingOccurrences(of: " ", with: "")
        
        // Basic validation - if it looks like a plate, return it
        if cleanedString.count >= 3 && cleanedString.count <= 8 {
            return [PlateEntity(id: cleanedString, plateNumber: cleanedString)]
        }
        
        return []
    }
}

struct FindPlateIntent: AppIntent {
    static var title: LocalizedStringResource = "Find Plate"
    static var description = IntentDescription("Search for a license plate")
    
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Plate Number")
    var plateNumber: PlateEntity
    
    func perform() async throws -> some IntentResult {
        let plateText = plateNumber.plateNumber.uppercased()

        guard PlateValidator.isComplete(plateText) else {
            throw $plateNumber.needsValueError("Please provide a valid license plate number in format ABC1234")
        }
        
        await MainActor.run {
            IntentHandler.shared.searchPlate(plate: plateText)
        }
        
        // Provide better Siri feedback
        return .result(dialog: "Searching for license plate \(plateText) in PlateFinder")
    }
}

enum PlateFinderShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        return [
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
        ]
    }
}
