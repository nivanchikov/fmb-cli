import Foundation

enum LunchMoneyAssetType: String, Codable {
    case cash
    case credit
    case investment
    case realEstate = "real estate"
    case loan
    case vehicle
    case cryptocurrency
    case employeeCompensation = "employee compensation"
    case otherLiability = "other liability"
    case otherAsset = "other asset"
}

struct LunchMoneyAsset: Codable {
    let id: Int
    let typeName: LunchMoneyAssetType
    let subtypeName: String?
    let name: String
    let displayName: String?
    let balance: String
    let toBase: Double?
    let balanceAsOf: Date
    let closedOn: Date?
    let currency: String
    let institutionName: String?
    let excludeTransactions: Bool
    let createdAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case typeName = "type_name"
        case subtypeName = "subtype_name"
        case name
        case displayName = "display_name"
        case balance
        case toBase = "to_base"
        case balanceAsOf = "balance_as_of"
        case closedOn = "closed_on"
        case currency
        case institutionName = "institution_name"
        case excludeTransactions = "exclude_transactions"
        case createdAt = "created_at"
    }
}

struct LunchMoneyAssetsListResponse: Codable {
    let assets: [LunchMoneyAsset]
}
