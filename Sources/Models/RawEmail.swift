import Foundation

struct RawEmail: Codable {
    enum Status: String, Codable {
        case unprocessed
        case processed
        case needsReview = "needs_review"
        case noPayload = "no_payload"
    }
    
    struct ID: Codable {
        let id: String
    }

    let id: String
    let createdAt: Date
    let status: Status
    let payload: String?
}
