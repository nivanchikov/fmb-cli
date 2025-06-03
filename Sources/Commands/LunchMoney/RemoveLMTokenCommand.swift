import ArgumentParser
import Noora

struct RemoveLMTokenCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "remove",
        abstract: "Remove LunchMoney API token."
    )

    func run() async throws {
        guard try LunchMoneyClient.hasToken else {
            Noora().success(.alert("No LunchMoney API token found."))
            return
        }

        let shouldRemove = Noora().yesOrNoChoicePrompt(
            question: "Do you want to remove the LunchMoney API token?"
        )

        guard shouldRemove else {
            return
        }

        do {
            try LunchMoneyClient.removeToken()
            Noora().success(.alert("LunchMoney API token removed."))
        } catch {
            Noora().error(.alert("Failed to remove LunchMoney API token: \(error)"))
        }
    }
}
