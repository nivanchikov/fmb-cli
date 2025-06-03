import Foundation

struct GmailMessageList: Codable {
    let messages: [GmailIDMessage]
    let nextPageToken: String?
    let resultSizeEstimate: Int
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
    
        self.nextPageToken = try container.decodeIfPresent(String.self, forKey: .nextPageToken)
        self.resultSizeEstimate = try container.decode(Int.self, forKey: .resultSizeEstimate)
        self.messages = try container.decodeIfPresent([GmailIDMessage].self, forKey: .messages) ?? []
    }
}

struct GmailIDMessage: Codable {
    let id: String
}
