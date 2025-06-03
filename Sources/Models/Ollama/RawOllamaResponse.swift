import Foundation

struct RawOllamaResponse: Codable {
    let response: String
    let done: Bool
}
