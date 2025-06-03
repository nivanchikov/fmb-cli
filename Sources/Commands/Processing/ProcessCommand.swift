import ArgumentParser
import ErrorKit
import Noora

struct ProcessCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "process",
        abstract: "Process your Gmail inbox for new transactions"
    )

    func run() async throws {
        do {
            try await Noora().progressStep(message: "Fetching mail") { _ in
                try await GoogleClient.fetchMail()
            }
            
//            try await Noora().progressBarStep(message: "Processing transactions") { update in
                try await MessageProcessor.processEmails { current, total in
                    print("Processing \(current) of \(total)")
//                    update(Double(current) / Double(total))
                }
//            }
        } catch {
            print(ErrorKit.errorChainDescription(for: error))
            throw error
        }
    }
}
