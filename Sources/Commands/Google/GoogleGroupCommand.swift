import ArgumentParser

struct GoogleGroupCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "google",
        abstract: "Manage your Gmail authentication status.",
        subcommands: [
            GoogleLoginCommand.self,
            GoogleLogoutCommand.self,
        ]
    )
}
