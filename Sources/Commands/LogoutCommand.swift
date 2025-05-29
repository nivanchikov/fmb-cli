import ArgumentParser

struct LogoutCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "logout",
        abstract: "Log out of the FMB service."
    )

    func run() async throws {
        print("Logged out successfully.")
    }
}
