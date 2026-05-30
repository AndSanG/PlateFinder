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
        case .networkError:         return "Network connection failed. Please try again."
        case .noDataFound:          return "No vehicle found for this plate number."
        case .invalidPlateFormat:   return "Invalid plate format."
        case .parsingError(let m):  return "Could not read server response: \(m)"
        case .serverError:          return "Server error. Please try again later."
        }
    }
}
