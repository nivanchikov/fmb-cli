import ArgumentParser
import Noora

struct GoogleLogoutCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "logout",
        abstract: "Log out of your Gmail inbox."
    )

    func run() async throws {
        guard try KeychainWrapper.hasGoogleTokens() else {
            Noora().success(.alert("You are already logged out."))
            return
        }

        let shouldLogout = Noora().yesOrNoChoicePrompt(
            title: "Logout",
            question: "Do you want to logout from your Google account?",
            defaultAnswer: false
        )

        guard shouldLogout else {
            return
        }

        do {
            try KeychainWrapper.deleteGoogleTokens()
            Noora().success(.alert("You have been logged out."))
        } catch {
            Noora().error(.alert("Failed to log out: \(error)"))
        }
    }
}
