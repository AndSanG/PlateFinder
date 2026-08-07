public enum CarInfoError: Error, Equatable, Sendable {
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

    public var userMessage: String {
        switch self {
        case .networkError:         return "network_error"
        case .noDataFound:          return "no_data_found"
        case .invalidPlateFormat:   return "invalid_plate_format"
        case .parsingError:         return "parsing_error"
        case .serverError:          return "server_error"
        }
    }
}
