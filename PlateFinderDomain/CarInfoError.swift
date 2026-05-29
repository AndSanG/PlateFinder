public enum CarInfoError: Error, Equatable {
    case networkError(Error)
    case noDataFound
    case invalidPlateFormat
    case parsingError(String)
    case serverError

    // Associated values are not compared — callers check the case, not the payload.
    public static func == (lhs: CarInfoError, rhs: CarInfoError) -> Bool {
        switch (lhs, rhs) {
        case (.networkError, .networkError),
             (.noDataFound, .noDataFound),
             (.invalidPlateFormat, .invalidPlateFormat),
             (.parsingError, .parsingError),
             (.serverError, .serverError): return true
        default: return false
        }
    }
}
