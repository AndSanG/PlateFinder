import Foundation

extension SearchHistoryItem: Codable {
    private enum CodingKeys: String, CodingKey {
        case plateNumber, searchDate, car
    }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        plateNumber = try c.decode(String.self,   forKey: .plateNumber)
        searchDate  = try c.decode(Date.self,     forKey: .searchDate)
        car         = try c.decodeIfPresent(Car.self, forKey: .car)
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(plateNumber,        forKey: .plateNumber)
        try c.encode(searchDate,         forKey: .searchDate)
        try c.encodeIfPresent(car,       forKey: .car)
    }
}

extension SearchHistoryItem {
    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale.current
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: searchDate, relativeTo: Date())
    }
}
