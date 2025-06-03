import Foundation

struct KeychainWrapper {
    enum Constants {
        static let googleTokensKey = "fmb-cli.google_tokens"
        static let lunchMoneyAPIKey = "fmb-cli.lm_api_key"
        static let service = "com.nivanchikov.fmb-cli"
    }
    
    private static func makeBaseDirectoryURL() throws {
        try FileManager.default.createDirectory(
            at: baseDirectory,
            withIntermediateDirectories: true
        )
    }
    
    private static var baseDirectory: URL {
        URL.applicationSupportDirectory.appending(
            path: Constants.service,
            directoryHint: .isDirectory
        )
    }
    
    private static func url(for key: String) -> URL {
        baseDirectory.appending(path: key, directoryHint: .notDirectory)
    }

    private static func getData(_ key: String) throws -> Data? {
        let url = url(for: key)
        
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            return nil
        }
        
        return try Data(contentsOf: url)
    }
    
    private static func contains(_ key: String) -> Bool {
        let url = url(for: key)
        return FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
    }
    
    private static func get(_ key: String) throws -> String? {
        guard let data = try getData(key) else {
            return nil
        }
        return String(decoding: data, as: UTF8.self)
    }
    
    private static func set(_ data: Data, key: String) throws {
        try makeBaseDirectoryURL()
        
        let url = url(for: key)
        try data.write(to: url)
    }
    
    private static func set(_ string: String, key: String) throws {
        let url = url(for: key)
        try Data(string.utf8).write(to: url)
    }
    
    private static func remove(_ key: String) throws {
        let url = url(for: key)
        
        if FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
            try FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Google
    static func getGoogleTokens() throws -> GoogleAccessRefreshTokens? {
        guard let data = try getData(Constants.googleTokensKey) else {
            return nil
        }

        let decoder = JSONDecoder()
        return try decoder.decode(GoogleAccessRefreshTokens.self, from: data)
    }

    static func saveGoogleTokens(_ tokens: GoogleAccessRefreshTokens) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(tokens)

        try set(data, key: Constants.googleTokensKey)
    }

    static func deleteGoogleTokens() throws {
        try remove(Constants.googleTokensKey)
    }

    static func hasGoogleTokens() -> Bool {
        contains(Constants.googleTokensKey)
    }

    // MARK: - Lunch Money
    static func saveLunchMoneyToken(_ token: String) throws {
        try set(token, key: Constants.lunchMoneyAPIKey)
    }

    static func deleteLunchMoneyToken() throws {
        try remove(Constants.lunchMoneyAPIKey)
    }

    static func getLunchMoneyToken() throws -> String? {
        return try get(Constants.lunchMoneyAPIKey)
    }

    static func hasLunchMoneyToken() throws -> Bool {
        return contains(Constants.lunchMoneyAPIKey)
    }
}
