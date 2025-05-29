import Foundation
import KeychainAccess

struct KeychainWrapper {
    enum Constants {
        static let googleTokensKey = "fmb-cli.google_tokens"
        static let service = "com.nivanchikov.fmb-cli"
    }

    static func saveGoogleTokens(_ tokens: GoogleTokens) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(tokens)

        let keychain = Keychain(service: Constants.service)
        try keychain.set(data, key: Constants.googleTokensKey)
    }

    static func getGoogleTokens() throws -> GoogleTokens? {
        let keychain = Keychain(service: Constants.service)

        guard let data = try keychain.getData(Constants.googleTokensKey) else {
            return nil
        }

        let decoder = JSONDecoder()
        return try decoder.decode(GoogleTokens.self, from: data)
    }
}
