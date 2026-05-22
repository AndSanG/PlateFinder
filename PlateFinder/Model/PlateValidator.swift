import Foundation

enum PlateFormat: Equatable {
    case empty
    case partiallyValid
    case invalid
    case bike    // AA123A
    case car     // AAA1234
    case special // CD1234
}

struct PlateValidator {

    // MARK: - Regex Patterns

    private static let bikeRegex = "^[A-Z]{2}\\d{3}[A-Z]$"
    private static let carRegex = "^[A-Z]{3}\\d{4}$"
    private static let specialRegex = "^[A-Z]{2}\\d{4}$"
    private static let partialRegex = "^[A-Z]{0,3}\\d{0,4}[A-Z]?$"

    // MARK: - Public API

    static func validate(_ plate: String) -> PlateFormat {
        guard !plate.isEmpty else { return .empty }

        if plate.matches(bikeRegex) { return .bike }
        if plate.matches(carRegex) { return .car }
        if plate.matches(specialRegex) { return .special }
        if plate.matches(partialRegex) { return .partiallyValid }

        return .invalid
    }

    static func isComplete(_ plate: String) -> Bool {
        let format = validate(plate)
        return format == .bike || format == .car || format == .special
    }

    static func isPartiallyValid(_ plate: String) -> Bool {
        validate(plate) != .invalid
    }

    static func vehicleIcon(for plate: String) -> String? {
        switch validate(plate) {
        case .bike: return "motorcycle.fill"
        case .car: return "car.fill"
        case .special: return "car.fill"
        default: return nil
        }
    }
}

// MARK: - String Helpers

private extension String {
    func matches(_ regex: String) -> Bool {
        range(of: regex, options: .regularExpression) != nil
    }
}
