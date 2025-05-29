import ArgumentParser

struct LMTokenCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "lm-token",
        abstract: "Manage your LunchMoney API token.",
        subcommands: [
            AddLMTokenCommand.self,
            RemoveLMTokenCommand.self,
        ]
    )
}
