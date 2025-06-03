import Foundation

struct OllamaRequest: Codable {
    let model: String
    let prompt: String
    let format: String
    let stream: Bool
    let think: Bool
    let system: String

    init(
        model: String = "qwen3:8b",
        system: String,
        prompt: String,
        format: String = "json",
        stream: Bool = false,
        think: Bool = false
    ) {
        self.model = model
        self.prompt = prompt
        self.format = format
        self.stream = stream
        self.think = think
        self.system = system
    }
}
