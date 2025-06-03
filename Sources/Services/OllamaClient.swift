import Foundation
import ErrorKit

enum OllamaClientError: Throwable, MyCatching {
    case invalidOllamaResponse
    case invalidOllamaResponseCode(Int)
    case caught(Error, function: String, line: Int)
    
    var userFriendlyMessage: String {
        switch self {
        case .invalidOllamaResponse:
            return "Invalid response from LLM"
        case .invalidOllamaResponseCode(let code):
            return "Invalid response code: \(code)"
        case let .caught(error, function, line):
            return "\(ErrorKit.userFriendlyMessage(for: error)):\(function)-\(line)"
        }
    }
}

struct OllamaClient {
    private static let transactionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(abbreviation: "MDT")
        return formatter
    }()
    
    static func extractTransaction(from payload: String) async throws(OllamaClientError) -> OllamaTransaction {
        var request = URLRequest(url: URL(string: "http://localhost:11434/api/generate")!)
        request.timeoutInterval = 60

        let ollamaRequest = OllamaRequest(system: OllamaPrompt.prompt, prompt: payload)

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = try OllamaClientError.catch {
            try JSONEncoder().encode(ollamaRequest)
        }

        let (data, response) = try await OllamaClientError.catch {
            try await URLSession.shared.data(for: request)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaClientError.invalidOllamaResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw OllamaClientError.invalidOllamaResponseCode(httpResponse.statusCode)
        }

        let ollamaResponse = try OllamaClientError.catch {
            try JSONDecoder().decode(RawOllamaResponse.self, from: data)
        }

        let transactionDecoder = JSONDecoder()
        transactionDecoder.dateDecodingStrategy = .formatted(transactionDateFormatter)

        let transaction = try OllamaClientError.catch {
            try transactionDecoder.decode(
                OllamaTransaction.self,
                from: Data(ollamaResponse.response.utf8)
            )
        }

        return transaction
    }
}
