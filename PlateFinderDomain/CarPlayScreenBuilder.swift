import Foundation

public enum CarPlayScreenBuilder {
    public static func build(
        state: SearchViewState,
        lastPlate: String,
        history: [SearchHistoryItem]
    ) -> CarPlayScreen {
        switch state {
        case .idle:
            return recentSearches(from: history)
        case .loading:
            return .loading(plate: lastPlate)
        case .success(let car):
            return result(from: car)
        case .error(let messageKey):
            return .error(messageKey: messageKey)
        }
    }

    private static func recentSearches(from history: [SearchHistoryItem]) -> CarPlayScreen {
        var seen = Set<String>()
        let rows: [CarPlayScreen.Row] = history.prefix(10).compactMap { item in
            guard !seen.contains(item.plateNumber) else { return nil }
            seen.insert(item.plateNumber)
            let subtitle = item.car.map { "\($0.manufacturer) \($0.model)" }
            return CarPlayScreen.Row(title: item.plateNumber, subtitle: subtitle, plate: item.plateNumber)
        }
        return .recentSearches(rows)
    }

    private static func result(from car: Car) -> CarPlayScreen {
        let detailRows: [CarPlayScreen.DetailRow] = [
            .init(labelKey: "color", value: car.colorName),
            .init(labelKey: "usage", value: car.service),
            .init(labelKey: "registration_validity", value: car.expirationDate),
        ]
        return .result(title: "\(car.manufacturer) \(car.model) \(car.year)", detailRows: detailRows)
    }
}
