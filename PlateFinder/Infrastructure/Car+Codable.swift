import Foundation

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
