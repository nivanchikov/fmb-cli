import Foundation

struct LunchMoneyTransaction: Codable {
    let id: String
    let amount: Decimal
    let date: Date
    let payee: String?
    let accountId: Int?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "external_id"
        case amount
        case date
        case payee
        case accountId = "asset_id"
        case notes
    }
}

struct LunchMoneyTransactionEnvelope: Codable {
    let transactions: [LunchMoneyTransaction]
    let applyRules: Bool
    let debitAsNegative: Bool
    
    enum CodingKeys: String, CodingKey {
        case transactions
        case applyRules = "apply_rules"
        case debitAsNegative = "debit_as_negative"
    }
}

enum LunchMoneyTransactionsResponse: Decodable {
    case success(ids: [Int])
    case error(messages: [String])
    
    enum CodingKeys: String, CodingKey {
        case ids
        case errors
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if container.contains(.ids) {
            self = .success(ids: try container.decode([Int].self, forKey: .ids))
        } else if container.contains(.errors) {
            self = .error(messages: try container.decode([String].self, forKey: .errors))
        } else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Failed to decode response"
                )
            )
        }
    }
}
