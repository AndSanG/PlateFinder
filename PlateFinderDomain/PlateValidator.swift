import Foundation

public enum PlateValidator {
    private static let carRegex     = "^[A-Z]{3}\\d{4}$"
    private static let partialRegex = "^[A-Z]{1,3}(\\d{1,4}[A-Z]?)?$"

    public static func validate(_ plate: String) -> PlateFormat {
        guard !plate.isEmpty else { return .empty }
        if plate.range(of: carRegex,     options: .regularExpression) != nil { return .car }
        if plate.range(of: partialRegex, options: .regularExpression) != nil { return .partiallyValid }
        return .invalid
    }
}
