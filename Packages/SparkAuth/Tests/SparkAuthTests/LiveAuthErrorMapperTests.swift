// Module: SparkAuthTests — LiveAuthErrorMapper

@testable import SparkAuth
import SparkCore
import Testing

struct LiveAuthErrorMapperTests {
    @Test func mapPhoneOTP400ToInvalidPhone() {
        let mapped = LiveAuthErrorMapper.mapPhoneOTP(AppError.server(statusCode: 400, message: nil))
        #expect(mapped as? AuthError == .invalidPhone)
    }

    @Test func mapPhoneOTP429ToRateLimited() {
        let mapped = LiveAuthErrorMapper.mapPhoneOTP(AppError.server(statusCode: 429, message: nil))
        #expect(mapped as? AuthError == .otpRateLimited)
    }

    @Test func mapPhoneVerification401ToInvalidCode() {
        let mapped = LiveAuthErrorMapper.mapPhoneVerification(AppError.unauthorized)
        #expect(mapped as? AuthError == .invalidVerificationCode)
    }
}
