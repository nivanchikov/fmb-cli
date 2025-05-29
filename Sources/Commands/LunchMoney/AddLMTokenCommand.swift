import ArgumentParser
import Foundation
import Noora

struct AddLMTokenCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add",
        abstract: "Add or update LunchMoney API token."
    )

    func run() async throws {
        await start()
    }

    private func start() async {
        let token = Noora().textPrompt(
            title: "Lunch Money API token",
            prompt: "Your API token:",
            description: "It will be used to ingest data into your Lunch Money account."
        )

        let shouldVerify = Noora().yesOrNoChoicePrompt(
            question: "Do you want to verify the token against Lunch Money API?"
        )

        if shouldVerify {
            await verifyToken(token)
        } else {
            writeToken(token)
        }
    }

    private func verifyToken(_ token: String) async {
        var request = URLRequest(url: URL(string: "https://dev.lunchmoney.app/v1/me")!)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            let user = try decoder.decode(LunchMoneyUser.self, from: data)

            let confirmed = Noora().yesOrNoChoicePrompt(
                question: "Is your account registered under \(user.userName) / \(user.userEmail)?"
            )

            guard confirmed else {
                let shouldInputAnother = Noora().yesOrNoChoicePrompt(
                    question:
                        "Do you want to update the API key?"
                )

                if shouldInputAnother {
                    await start()
                }
                return
            }

            writeToken(token)
        } catch {
            Noora().error(.alert("Failed to verify token: \(error.localizedDescription)"))

            let retry = Noora().yesOrNoChoicePrompt(
                question: "Do you want to retry?"
            )

            if retry {
                await verifyToken(token)
            }
        }
    }

    private func writeToken(_ token: String) {
        do {
            try KeychainWrapper.saveLunchMoneyToken(token)
            Noora().success("Token saved successfully")
        } catch {
            Noora().error(.alert("\(error.localizedDescription)"))
        }
    }
}
