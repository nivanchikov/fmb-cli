import ArgumentParser
import Noora

struct GoogleLogoutCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "logout",
        abstract: "Log out of your Gmail inbox."
    )

    func run() async throws {
        guard try GoogleClient.isSignedIn else {
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
            try GoogleClient.signOut()
            Noora().success(.alert("You have been logged out."))
        } catch {
            Noora().error(.alert("Failed to log out: \(error)"))
        }
    }
}
