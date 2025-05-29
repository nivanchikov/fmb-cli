import Foundation
import KeychainAccess

struct KeychainWrapper {
    enum Constants {
        static let googleTokensKey = "fmb-cli.google_tokens"
        static let lunchMoneyAPIKey = "fmb-cli.lm_api_key"
        static let service = "com.nivanchikov.fmb-cli"
    }

    // MARK: - Google
    static func getGoogleTokens() throws -> GoogleTokens? {
        let keychain = Keychain(service: Constants.service)

        guard let data = try keychain.getData(Constants.googleTokensKey) else {
            return nil
        }

        let decoder = JSONDecoder()
        return try decoder.decode(GoogleTokens.self, from: data)
    }

    static func saveGoogleTokens(_ tokens: GoogleTokens) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(tokens)

        let keychain = Keychain(service: Constants.service)
        try keychain.set(data, key: Constants.googleTokensKey)
    }

    static func deleteGoogleTokens() throws {
        let keychain = Keychain(service: Constants.service)
        try keychain.remove(Constants.googleTokensKey)
    }

    static func hasGoogleTokens() throws -> Bool {
        let keychain = Keychain(service: Constants.service)

        return try keychain.contains(
            Constants.googleTokensKey,
            withoutAuthenticationUI: true
        )
    }

    // MARK: - Lunch Money
    static func saveLunchMoneyToken(_ token: String) throws {
        let keychain = Keychain(service: Constants.service)
        try keychain.set(token, key: Constants.lunchMoneyAPIKey)
    }

    static func deleteLunchMoneyToken() throws {
        let keychain = Keychain(service: Constants.service)
        try keychain.remove(Constants.lunchMoneyAPIKey)
    }

    static func getLunchMoneyToken() throws -> String? {
        let keychain = Keychain(service: Constants.service)
        return try keychain.get(Constants.lunchMoneyAPIKey)
    }

    static func hasLunchMoneyToken() throws -> Bool {
        let keychain = Keychain(service: Constants.service)
        return try keychain.contains(
            Constants.lunchMoneyAPIKey,
            withoutAuthenticationUI: true
        )
    }
}
