import Testing
@testable import PlateFinder

@Suite struct PlateValidatorTests {

    @Test func validate_returnsEmptyOnEmptyString() {
        #expect(PlateValidator.validate("") == .empty)
    }
}
