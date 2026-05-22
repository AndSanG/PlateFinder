import Foundation

// MARK: - Codable conformances (infrastructure concern)
// Synthesis can't cross files, so these are explicit.

extension Car: Codable {
    private enum CodingKeys: String, CodingKey {
        case plate, manufacturer, colorName, registrationYear
        case model, segment, registrationDate, year, service
        case expirationDate, tint, tintExpirationDate
    }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        plate              = try c.decode(String.self, forKey: .plate)
        manufacturer       = try c.decode(String.self, forKey: .manufacturer)
        colorName          = try c.decode(String.self, forKey: .colorName)
        registrationYear   = try c.decode(String.self, forKey: .registrationYear)
        model              = try c.decode(String.self, forKey: .model)
        segment            = try c.decode(String.self, forKey: .segment)
        registrationDate   = try c.decode(String.self, forKey: .registrationDate)
        year               = try c.decode(String.self, forKey: .year)
        service            = try c.decode(String.self, forKey: .service)
        expirationDate     = try c.decode(String.self, forKey: .expirationDate)
        tint               = try c.decode(String.self, forKey: .tint)
        tintExpirationDate = try c.decode(String.self, forKey: .tintExpirationDate)
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(plate,              forKey: .plate)
        try c.encode(manufacturer,       forKey: .manufacturer)
        try c.encode(colorName,          forKey: .colorName)
        try c.encode(registrationYear,   forKey: .registrationYear)
        try c.encode(model,              forKey: .model)
        try c.encode(segment,            forKey: .segment)
        try c.encode(registrationDate,   forKey: .registrationDate)
        try c.encode(year,               forKey: .year)
        try c.encode(service,            forKey: .service)
        try c.encode(expirationDate,     forKey: .expirationDate)
        try c.encode(tint,               forKey: .tint)
        try c.encode(tintExpirationDate, forKey: .tintExpirationDate)
    }
}

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

// MARK: - Preview helpers

extension Car {
    static var mock: Car {
        Car(
            plate: "ABC1234", manufacturer: "TOYOTA", colorName: "AMARILLO",
            registrationYear: "2025", model: "AA COROLLA 1.6", segment: "AUTOMOVIL",
            registrationDate: "14-06-2025", year: "2009", service: "USO PUBLICO",
            expirationDate: "31-05-2030", tint: "No existe registro de polarizado",
            tintExpirationDate: ""
        )
    }
}

// MARK: - View helpers (presentation concern)

extension SearchHistoryItem {
    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale.current
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: searchDate, relativeTo: Date())
    }
}

// MARK: - PlateValidator convenience (app-layer shims for views and intents)

extension PlateValidator {
    static func isComplete(_ plate: String) -> Bool {
        let f = validate(plate)
        return f == .car || f == .bike || f == .special
    }
    static func isPartiallyValid(_ plate: String) -> Bool {
        validate(plate) != .invalid && validate(plate) != .empty
    }
    static func vehicleIcon(for plate: String) -> String? {
        switch validate(plate) {
        case .bike:            return "motorcycle.fill"
        case .car, .special:   return "car.fill"
        default:               return nil
        }
    }
}

// MARK: - UserDefaultsCarStore

final class UserDefaultsCarStore: CarStore, FavoritesStore {
    private let defaults: UserDefaults
    private let historyKey = "search_history"
    private let favoritesKey = "favorites"
    private let maxHistoryItems = 50

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: CarStore

    func retrieve() async throws -> [SearchHistoryItem] {
        guard let data = defaults.data(forKey: historyKey),
              let items = try? JSONDecoder().decode([SearchHistoryItem].self, from: data) else {
            return []
        }
        return items
    }

    func insert(_ item: SearchHistoryItem) async throws {
        var items = (try? await retrieve()) ?? []
        items.removeAll { $0.plateNumber == item.plateNumber }
        items.insert(item, at: 0)
        if items.count > maxHistoryItems { items = Array(items.prefix(maxHistoryItems)) }
        if let data = try? JSONEncoder().encode(items) { defaults.set(data, forKey: historyKey) }
    }

    func delete(_ item: SearchHistoryItem) async throws {
        var items = (try? await retrieve()) ?? []
        items.removeAll { $0.plateNumber == item.plateNumber }
        if let data = try? JSONEncoder().encode(items) { defaults.set(data, forKey: historyKey) }
    }

    func deleteAll() async throws {
        defaults.removeObject(forKey: historyKey)
    }

    // MARK: FavoritesStore

    func retrieveFavorites() async throws -> [String] {
        defaults.stringArray(forKey: favoritesKey) ?? []
    }

    func insertFavorite(_ plateNumber: String) async throws {
        var favs = (try? await retrieveFavorites()) ?? []
        if !favs.contains(plateNumber) {
            favs.append(plateNumber)
            defaults.set(favs, forKey: favoritesKey)
        }
    }

    func deleteFavorite(_ plateNumber: String) async throws {
        var favs = (try? await retrieveFavorites()) ?? []
        favs.removeAll { $0 == plateNumber }
        defaults.set(favs, forKey: favoritesKey)
    }
}
