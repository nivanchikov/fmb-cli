import Foundation

struct LunchMoneyUser: Codable {
    let userName: String
    let userEmail: String
    let userId: Int
    let accountId: Int
    let budgetName: String
    let primaryCurrency: String
    let apiKeyLabel: String
}
