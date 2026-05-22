import Foundation

public struct SearchHistoryItem: Equatable {
    public let plateNumber: String
    public let searchDate: Date
    public let car: Car?

    public init(plateNumber: String, searchDate: Date, car: Car?) {
        self.plateNumber = plateNumber
        self.searchDate = searchDate
        self.car = car
    }
}
