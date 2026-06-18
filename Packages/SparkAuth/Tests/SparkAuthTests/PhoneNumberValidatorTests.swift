// Module: SparkAuthTests — Phone number validation.

@testable import SparkAuth
import Testing

struct PhoneNumberValidatorTests {
    @Test func acceptsValidCNMobile() {
        #expect(PhoneNumberValidator.isValidCNMobile("18812345678"))
        #expect(PhoneNumberValidator.isValidCNMobile("188 1234 5678"))
    }

    @Test func rejectsShortOrInvalidPrefix() {
        #expect(!PhoneNumberValidator.isValidCNMobile("08812345678"))
        #expect(!PhoneNumberValidator.isValidCNMobile("1881234567"))
        #expect(!PhoneNumberValidator.isValidCNMobile(""))
    }

    @Test func normalizedDigitsStripsFormatting() {
        #expect(PhoneNumberValidator.normalizedDigits("188 1234-5678") == "18812345678")
    }
}
