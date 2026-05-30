import Foundation

extension CarInfoError: LocalizedError {
    public var errorDescription: String? { userMessage }
}
