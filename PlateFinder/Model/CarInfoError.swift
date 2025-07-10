
import Foundation

enum CarInfoError: LocalizedError {
    case networkError(Error)
    case noDataFound
    case invalidPlateFormat
    case parsingError(String)
    case serverError
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "network_error".localized
        case .noDataFound:
            return "no_data_found".localized
        case .invalidPlateFormat:
            return "invalid_plate_format".localized
        case .parsingError:
            return "parsing_error".localized
        case .serverError:
            return "server_error".localized
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "check_internet_connection".localized
        case .noDataFound:
            return "ensure_plate_registered".localized
        case .invalidPlateFormat:
            return "use_correct_format".localized
        case .parsingError, .serverError:
            return "try_again_later".localized
        }
    }
}
