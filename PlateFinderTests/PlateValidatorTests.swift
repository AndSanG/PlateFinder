import Testing
@testable import PlateFinder

@Suite struct PlateValidatorTests {

    @Test func validate_returnsEmptyOnEmptyString() {
        #expect(PlateValidator.validate("") == .empty)
    }

    @Test(arguments: ["1ABC", "ABCD", "1234", "ABC12345", "!@#"])
    func validate_returnsInvalidForUnrecognizedInput(plate: String) {
        #expect(PlateValidator.validate(plate) == .invalid)
    }

    @Test(arguments: ["A", "AB", "ABC", "ABC1", "ABC12", "ABC123", "AB1", "AB12", "AB123"])
    func validate_returnsPartiallyValidForIncompleteInput(plate: String) {
        #expect(PlateValidator.validate(plate) == .partiallyValid)
    }

    @Test(arguments: ["ABC1234", "ZZZ9999", "PBX0001"])
    func validate_returnsCarForCompleteCarPlate(plate: String) {
        #expect(PlateValidator.validate(plate) == .car)
    }

    @Test(arguments: ["AB123A", "ZZ999Z"])
    func validate_returnsBikeForCompleteBikePlate(plate: String) {
        #expect(PlateValidator.validate(plate) == .bike)
    }
}
