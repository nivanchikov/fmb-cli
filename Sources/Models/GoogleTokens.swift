import Foundation

struct GoogleAccessRefreshTokens: Codable {
    let accessToken: String
    let expiresIn: Int
    let refreshToken: String
    let scope: String
    let tokenType: String
    let refreshTokenExpiresIn: Int
}

struct GoogleAccessToken: Codable {
    let accessToken: String
    let expiresIn: Int
    let scope: String
    let tokenType: String
}
