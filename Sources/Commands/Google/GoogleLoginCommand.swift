import ArgumentParser
import Foundation
import HTTPTypes
import Noora
import Swifter
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

    enum Constants {
        static let redirectURL = "http://localhost:8080/callback"
        static let scopes = "https://www.googleapis.com/auth/gmail.modify"
    }

    func run() async throws {
        try await Noora().progressStep(
            message: "Authenticating with Google...",
            successMessage: "Successfully signed in!",
            errorMessage: "Failed to sign in!",
            showSpinner: true,
        ) { messageUpdate in
            messageUpdate("Fetching Google OAuth code...")
            let code = try await executeOAuth()

            messageUpdate("Exchanging code to tokens...")
            let tokens = try await exchangeCode(code)

            messageUpdate("Storing tokens...")
            try KeychainWrapper.saveGoogleTokens(tokens)
        }
    }

    private func executeOAuth() async throws -> String {
        let server = HttpServer()
        try server.start(8080, forceIPv4: true)

        defer {
            server.stop()
        }

        let state = UUID()
        try openOAuthPage(state: state)

        let code = try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<String, Error>) in
            server["callback"] = { request in
                guard
                    let code = request.queryParams.first(where: { $0.0 == "code" })?.1,
                    let serverState = request.queryParams.first(where: { $0.0 == "state" })?.1,
                    serverState == state.uuidString
                else {
                    continuation.resume(throwing: LoginError.missingCodeOrBadState)
                    return .badRequest(.html("Error"))
                }

                continuation.resume(returning: code)
                return .ok(.html("✅ Authorization complete. You can close this window."))
            }
        }

        try await Task.sleep(for: .milliseconds(200))
        return code
    }

    private func openOAuthPage(state: UUID) throws {
        let url = try buildOAuthURL(state: state)

        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/open")
        process.arguments = [
            url.absoluteString
        ]

        try process.run()
        process.waitUntilExit()
    }

    private func buildOAuthURL(state: UUID) throws -> URL {
        guard
            var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")
        else {
            throw LoginError.failedToBuildOAuthURL
        }

        components.queryItems = [
            .init(name: "client_id", value: Secrets.googleClientID),
            .init(name: "redirect_uri", value: Constants.redirectURL),
            .init(name: "response_type", value: "code"),
            .init(name: "scope", value: Constants.scopes),
            .init(name: "access_type", value: "offline"),
            .init(name: "prompt", value: "consent"),
            .init(name: "state", value: state.uuidString),
        ]

        guard let url = components.url else {
            throw LoginError.failedToBuildOAuthURL
        }

        return url
    }

    private func exchangeCode(_ code: String) async throws -> GoogleTokens {
        let params = [
            "code": code,
            "client_id": Secrets.googleClientID,
            "client_secret": Secrets.googleClientSecret,
            "redirect_uri": Constants.redirectURL,
            "grant_type": "authorization_code",
        ]

        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )

        request.httpBody =
            params
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            let tokenResponse = try decoder.decode(GoogleTokens.self, from: data)
            return tokenResponse
        } catch {
            let rawResponse = String(decoding: data, as: UTF8.self)
            throw LoginError.failedToDecodeToken(response: rawResponse)
        }
    }
}
