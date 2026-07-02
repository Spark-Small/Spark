// Module: SparkAuthTests — PhoneNumberValidator

@testable import SparkAuth
import Testing

struct PhoneNumberValidatorTests {
    @Test func acceptsCNMobileWithSpaces() {
        #expect(PhoneNumberValidator.isValidCNMobile("138 0013 8000"))
        #expect(PhoneNumberValidator.normalizedDigits("138 0013 8000") == "13800138000")
    }

    @Test func rejectsShortNumbers() {
        #expect(!PhoneNumberValidator.isValidCNMobile("138001380"))
    }

    @Test func rejectsNonMobilePrefix() {
        #expect(!PhoneNumberValidator.isValidCNMobile("23800138000"))
    }

    @Test func clampsMobileAndVerificationCodeInput() {
        #expect(PhoneNumberValidator.clampedCNMobileInput("138 0013 8000 99") == "13800138000")
        #expect(PhoneNumberValidator.clampedVerificationCode("12ab34567") == "123456")
    }
}
