import Foundation

public enum PlateValidator {
    public static func validate(_ plate: String) -> PlateFormat {
        guard !plate.isEmpty else { return .empty }
        return .invalid
    }
}
