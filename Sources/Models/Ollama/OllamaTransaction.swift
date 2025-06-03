import Foundation

struct OllamaTransaction: Codable {
    let date: Date?
    let account: String?
    let type: TransactionType?
    let institution: String?
    let amount: Decimal?
    let merchant: String?
}
