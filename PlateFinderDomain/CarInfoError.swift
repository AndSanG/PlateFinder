public enum CarInfoError: Error, Equatable {
    case connectivity
    case serverError
    case noDataFound
    case invalidData
    case invalidPlateFormat
}
