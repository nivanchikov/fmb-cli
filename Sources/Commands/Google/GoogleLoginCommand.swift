import ArgumentParser
import Foundation
import HTTPTypes
import Noora
import System

enum LoginError: Error {
    case failedToBuildOAuthURL
    case missingCodeOrBadState
    case failedToDecodeToken(response: String)
}

struct GoogleLoginCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "login",
        abstract: "Authenticate fmb-cli to access your Gmail inbox."
    )

    func run() async throws {
        try await Noora().progressStep(
            message: "Authenticating with Google...",
            successMessage: "Successfully signed in!",
            errorMessage: "Failed to sign in!",
            showSpinner: true,
        ) { messageUpdate in
            try await GoogleClient.signIn()
        }
    }

}
