public struct Car: Equatable {
    public let plate: String
    public let manufacturer: String
    public let colorName: String
    public let registrationYear: String
    public let model: String
    public let segment: String
    public let registrationDate: String
    public let year: String
    public let service: String
    public let expirationDate: String
    public let tint: String
    public let tintExpirationDate: String

    public init(
        plate: String,
        manufacturer: String,
        colorName: String,
        registrationYear: String,
        model: String,
        segment: String,
        registrationDate: String,
        year: String,
        service: String,
        expirationDate: String,
        tint: String,
        tintExpirationDate: String
    ) {
        self.plate = plate
        self.manufacturer = manufacturer
        self.colorName = colorName
        self.registrationYear = registrationYear
        self.model = model
        self.segment = segment
        self.registrationDate = registrationDate
        self.year = year
        self.service = service
        self.expirationDate = expirationDate
        self.tint = tint
        self.tintExpirationDate = tintExpirationDate
    }
}
