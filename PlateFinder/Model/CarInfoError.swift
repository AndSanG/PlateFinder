
import Foundation

enum CarInfoError: LocalizedError {
    case htmlFetchingError(Error)
    case tableNotFound
    case parsingError(String)
    case rowOrCellNotFound(String)

    var errorDescription: String? {
        switch self {
        case .htmlFetchingError(let error):
            return "Failed to fetch HTML: \(error.localizedDescription)"
        case .tableNotFound:
            return "Could not find the data table in the HTML response."
        case .parsingError(let message):
            return "A parsing error occurred: \(message)"
        case .rowOrCellNotFound(let details):
            return "Could not find a required row or cell: \(details)"
        }
    }
}
