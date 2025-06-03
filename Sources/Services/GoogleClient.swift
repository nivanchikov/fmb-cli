import Foundation
import SwiftSoup
import Swifter
import ErrorKit

enum GoogleClientError: Throwable, Catching {
    case signedOut
    case invalidURL
    case invalidResponse(code: Int?)
    case caught(Error)
    
    var userFriendlyMessage: String {
        switch self {
        case .signedOut:
            return "You are signed out. Please sign in again."
        case .invalidURL:
            return "Invalid URL."
        case let .invalidResponse(code):
            return "Invalid response. Code \(code)"
        case .caught(let error):
            return ErrorKit.userFriendlyMessage(for: error)
        }
    }
}

struct GoogleClient {
    enum Constants {
        static let redirectURL = "http://localhost:8080/callback"
        static let scopes = [
            "https://www.googleapis.com/auth/gmail.labels",
            "https://www.googleapis.com/auth/gmail.modify"
        ]
    }
}

struct EmailsListResponse {
    let ids: Set<String>
    let cursor: String?
}

// MARK: - Mail processing
extension GoogleClient {
    static func fetchMail() async throws {
        try await refreshTokens()

        let latestIDs = try await DatabaseClient.getRawEmailIDs(count: 20)

        try await getMail(dbIds: latestIDs)
    }

    private static func getMail(dbIds: Set<String>, count: Int = 20, cursor: String? = nil)
        async throws(GoogleClientError)
    {
        let response = try await getEmailsList(count: count, cursor: cursor)

        guard !response.ids.isEmpty else {
            return
        }

        let idsToProcess = response.ids.subtracting(dbIds)

        guard !idsToProcess.isEmpty else {
            return
        }

        let messages = try await GoogleClientError.catch {
            try await withThrowingTaskGroup { group in
                for id in idsToProcess {
                    group.addTask {
                        try await Task.sleep(for: .milliseconds(Int.random(in: 0...200)))
                        return try await fetchMessage(for: id)
                    }
                }

                var results: [GmailFullMessage] = []
                for try await message in group {
                    results.append(message)
                }
                return results
            }
        }

        var emails: [RawEmail] = []

        for message in messages {
            let payload = message.extractMessageBody()
            let intDate = Int64(message.internalDate)!
            let date = Date(timeIntervalSince1970: TimeInterval(intDate / 1000))

            let email = RawEmail(
                id: message.id,
                createdAt: date,
                status: .unprocessed,
                payload: payload
            )

            emails.append(email)
        }

        try await GoogleClientError.catch {
            try await DatabaseClient.storeRawEmails(emails)
        }
        
        if idsToProcess.count >= count, let cursor = response.cursor {
            try await getMail(dbIds: dbIds, count: count, cursor: cursor)
        }
    }

    private static func getEmailsList(count: Int = 20, cursor: String?) async throws(GoogleClientError)
        -> EmailsListResponse
    {
        var queryItems: [URLQueryItem] = [
            .init(name: "maxResults", value: "\(count)"),
            .init(name: "labelIds", value: "Label_2265031816564324563")
        ]

        if let cursor {
            queryItems.append(.init(name: "pageToken", value: cursor))
        }

        guard
            var components = URLComponents(
                string: "https://gmail.googleapis.com/gmail/v1/users/me/messages"
            )
        else {
            throw GoogleClientError.invalidURL
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw GoogleClientError.invalidURL
        }
        
        let tokens = try GoogleClientError.catch {
            try KeychainWrapper.getGoogleTokens()
        }

        guard let tokens else {
            throw GoogleClientError.signedOut
        }

        var request = URLRequest(url: url)
        request.addValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await GoogleClientError.catch {
            try await URLSession.shared.data(for: request)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleClientError.invalidResponse(code: nil)
        }
        
        guard httpResponse.statusCode == 200 else {
            throw GoogleClientError.invalidResponse(code: httpResponse.statusCode)
        }

        let list = try GoogleClientError.catch {
            do {
               return try JSONDecoder().decode(GmailMessageList.self, from: data)
            } catch {
                print(String(decoding: data, as: UTF8.self))
                throw error
            }
        }

        let ids = Set(list.messages.map(\.id))

        return EmailsListResponse(ids: ids, cursor: list.nextPageToken)
    }
    
    static func markProcessed(_ emailId: String) async throws(GoogleClientError) {
        try await GoogleClientError.catch {
            try await refreshTokens()
        }
        
        let tokens = try GoogleClientError.catch {
            try KeychainWrapper.getGoogleTokens()
        }

        guard let tokens else {
            throw GoogleClientError.signedOut
        }
        
        let params: [String: Any] = [
            "addLabelIds": [
                "Label_7501396617224479743"
            ],
            "removeLabelIds": [
                "Label_2265031816564324563"
            ]
        ]

        var request = URLRequest(url: URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/messages/\(emailId)/modify")!)
        request.addValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = try GoogleClientError.catch {
            try JSONSerialization.data(withJSONObject: params)
        }

        let (data, response) = try await GoogleClientError.catch {
            try await URLSession.shared.data(for: request)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleClientError.invalidResponse(code: nil)
        }
        
        guard httpResponse.statusCode == 200 else {
            throw GoogleClientError.invalidResponse(code: httpResponse.statusCode)
        }

        let idMessage = try GoogleClientError.catch {
            try JSONDecoder().decode(GmailIDMessage.self, from: data)
        }
    }

    private static func fetchMessage(for id: String) async throws(GoogleClientError) -> GmailFullMessage {
        guard
            var components = URLComponents(
                string: "https://gmail.googleapis.com/gmail/v1/users/me/messages/\(id)"
            )
        else {
            throw GoogleClientError.invalidURL
        }

        components.queryItems = [
            .init(name: "format", value: "full")
        ]

        guard let url = components.url else {
            throw GoogleClientError.invalidURL
        }
        
        let tokens = try GoogleClientError.catch {
            try KeychainWrapper.getGoogleTokens()
        }

        guard let tokens else {
            throw GoogleClientError.signedOut
        }

        var request = URLRequest(url: url)
        request.addValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await GoogleClientError.catch {
            try await URLSession.shared.data(for: request)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleClientError.invalidResponse(code: nil)
        }
        
        guard httpResponse.statusCode == 200 else {
            throw GoogleClientError.invalidResponse(code: httpResponse.statusCode)
        }

        return try GoogleClientError.catch {
            try JSONDecoder().decode(GmailFullMessage.self, from: data)
        }
    }
}

// MARK: - Authentication
extension GoogleClient {
    static var isSignedIn: Bool {
        KeychainWrapper.hasGoogleTokens()
    }

    static func signIn() async throws {
        let state = UUID()

        try openOAuthPage(state: state)

        let code = try await waitForCode(state: state)
        let tokens = try await exchangeCode(code)

        try KeychainWrapper.saveGoogleTokens(tokens)
    }

    static func signOut() throws {
        try KeychainWrapper.deleteGoogleTokens()
    }

    private static func refreshTokens() async throws {
        guard let oldTokens = try KeychainWrapper.getGoogleTokens() else {
            throw GoogleClientError.signedOut
        }

        let params = [
            "client_id": Secrets.googleClientID,
            "client_secret": Secrets.googleClientSecret,
            "refresh_token": oldTokens.refreshToken,
            "grant_type": "refresh_token",
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

            let tokenResponse = try decoder.decode(GoogleAccessToken.self, from: data)

            let newTokens = GoogleAccessRefreshTokens(
                accessToken: tokenResponse.accessToken,
                expiresIn: tokenResponse.expiresIn,
                refreshToken: oldTokens.refreshToken,
                scope: tokenResponse.scope,
                tokenType: tokenResponse.tokenType,
                refreshTokenExpiresIn: oldTokens.refreshTokenExpiresIn
            )

            try KeychainWrapper.saveGoogleTokens(newTokens)
        } catch {
            let rawResponse = String(decoding: data, as: UTF8.self)
            throw LoginError.failedToDecodeToken(response: rawResponse)
        }
    }

    private static func buildOAuthURL(state: UUID) throws -> URL {
        guard
            var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")
        else {
            throw LoginError.failedToBuildOAuthURL
        }

        components.queryItems = [
            .init(name: "client_id", value: Secrets.googleClientID),
            .init(name: "redirect_uri", value: Constants.redirectURL),
            .init(name: "response_type", value: "code"),
            .init(name: "scope", value: Constants.scopes.joined(separator: " ")),
            .init(name: "access_type", value: "offline"),
            .init(name: "prompt", value: "consent"),
            .init(name: "state", value: state.uuidString),
        ]

        guard let url = components.url else {
            throw LoginError.failedToBuildOAuthURL
        }

        return url
    }

    private static func openOAuthPage(state: UUID) throws {
        let url = try buildOAuthURL(state: state)

        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/open")
        process.arguments = [
            url.absoluteString
        ]

        try process.run()
        process.waitUntilExit()
    }

    private static func waitForCode(state: UUID) async throws -> String {
        let server = HttpServer()
        try server.start(8080, forceIPv4: true)

        defer {
            server.stop()
        }

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

    private static func exchangeCode(_ code: String) async throws -> GoogleAccessRefreshTokens {
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

            let tokenResponse = try decoder.decode(GoogleAccessRefreshTokens.self, from: data)
            return tokenResponse
        } catch {
            let rawResponse = String(decoding: data, as: UTF8.self)
            throw LoginError.failedToDecodeToken(response: rawResponse)
        }
    }
}
