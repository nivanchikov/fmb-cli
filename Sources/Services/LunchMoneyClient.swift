import Foundation
import ErrorKit

enum LunchMoneyClientError: Throwable, MyCatching {
    case missingAPIToken
    case invalidResponse(URL)
    case invalidResponseCode(Int, url: URL)
    case failedToCreateTransactions(errors: [String])
    case caught(Error, function: String, line: Int)
    
    var userFriendlyMessage: String {
        switch self {
        case .invalidResponse(let url):
            return "Invalid response for \(url)"
        case let .invalidResponseCode(code, url):
            return "Invalid response code \(code) for \(url)"
        case .missingAPIToken:
            return "API Token is missing. Please set the token via `fmb lm-token add`."
        case .failedToCreateTransactions(let errors):
            return "Failed to create transactions. Errors: \(errors.joined(separator: "\n"))"
        case .caught(let error, let function, let line):
            return "\(ErrorKit.userFriendlyMessage(for: error)):\(function)-\(line)"
        }
    }
}

struct LunchMoneyClient {
    private static let transactionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(abbreviation: "MDT")
        return formatter
    }()

    static var hasToken: Bool {
        get throws {
            try KeychainWrapper.hasLunchMoneyToken()
        }
    }

    static func saveToken(_ token: String) throws {
        try KeychainWrapper.saveLunchMoneyToken(token)
    }

    static func removeToken() throws {
        try KeychainWrapper.deleteLunchMoneyToken()
    }

    static func verifyToken(_ token: String) async throws -> LunchMoneyUser {
        var request = URLRequest(url: URL(string: "https://dev.lunchmoney.app/v1/me")!)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let user = try decoder.decode(LunchMoneyUser.self, from: data)
        return user
    }
    
    static func getAssets() async throws(LunchMoneyClientError) -> [LunchMoneyAsset] {
        let token = try LunchMoneyClientError.catch {
            try KeychainWrapper.getLunchMoneyToken()
        }
        
        guard let token else {
            throw LunchMoneyClientError.missingAPIToken
        }
        
        var request = URLRequest(url: URL(string: "https://dev.lunchmoney.app/v1/assets")!)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await LunchMoneyClientError.catch {
            try await URLSession.shared.data(for: request)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let stringDate = try container.decode(String.self)
            return try Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(stringDate)
        }
        
        let list = try LunchMoneyClientError.catch {
            try decoder.decode(LunchMoneyAssetsListResponse.self, from: data)
        }
        
        return list.assets
    }
    
    static func syncTransaction(
        _ transaction: LunchMoneyTransaction,
        debitAsNegative: Bool
    ) async throws(LunchMoneyClientError) {
        let token = try LunchMoneyClientError.catch {
            try KeychainWrapper.getLunchMoneyToken()
        }
        
        guard let token else {
            throw LunchMoneyClientError.missingAPIToken
        }
        
        let envelope = LunchMoneyTransactionEnvelope(
            transactions: [transaction],
            applyRules: false,
            debitAsNegative: debitAsNegative
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(transactionDateFormatter)
        
        let url = URL(string: "https://dev.lunchmoney.app/v1/transactions")!
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpMethod = "POST"
        request.httpBody = try LunchMoneyClientError.catch {
            try encoder.encode(envelope)
        }
        
        let (data, response) = try await LunchMoneyClientError.catch {
            try await URLSession.shared.data(for: request)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LunchMoneyClientError.invalidResponse(url)
        }
        
        guard httpResponse.statusCode == 200 else {
            throw LunchMoneyClientError.invalidResponseCode(httpResponse.statusCode, url: url)
        }
        
        let lmResponse = try LunchMoneyClientError.catch {
            do {
                return try JSONDecoder().decode(LunchMoneyTransactionsResponse.self, from: data)
            } catch {
                print("Decoding error: \(error), data: \(String(decoding: data, as: UTF8.self))")
                throw error
            }
        }
        
        switch lmResponse {
        case .success:
            break
        case let .error(messages):
            throw LunchMoneyClientError.failedToCreateTransactions(errors: messages)
        }
    }
}
