import ArgumentParser

@main
struct FMBCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "fmb",
        abstract: "A command-line tool to import email transactions.",
        subcommands: [
            LoginCommand.self,
            LogoutCommand.self,
        ]
    )
}
