import ArgumentParser

struct ProcessCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "process",
        abstract: "Process your Gmail inbox for new transactions"
    )

    func run() async throws {

    }
}
