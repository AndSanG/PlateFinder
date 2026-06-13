import Foundation

public enum CarPlayScreen: Equatable {
    public struct Row: Equatable, Sendable {
        public let title: String
        public let subtitle: String?
        public let plate: String

        public init(title: String, subtitle: String?, plate: String) {
            self.title = title
            self.subtitle = subtitle
            self.plate = plate
        }
    }

    public struct DetailRow: Equatable, Sendable {
        public let labelKey: String
        public let value: String

        public init(labelKey: String, value: String) {
            self.labelKey = labelKey
            self.value = value
        }
    }

    case recentSearches([Row])
    case loading(plate: String)
    case result(title: String, detailRows: [DetailRow])
    case error(messageKey: String)
}
