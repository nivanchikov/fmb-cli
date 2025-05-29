import ArgumentParser

struct RemoveLMTokenCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "remove",
        abstract: "Remove LunchMoney API token."
    )

    func run() async throws {
        print("Removing LunchMoney API token...")
    }
}
