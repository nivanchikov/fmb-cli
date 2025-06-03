import Foundation
import SwiftSoup

struct GmailFullMessage: Codable {
    let id: String
    let internalDate: String
    let snippet: String?
    let payload: GmailPayload
}

struct GmailPayload: Codable {
    let mimeType: String
    let body: GmailBody?
    let parts: [GmailPayload]?
}

struct GmailBody: Codable {
    let data: String?  // base64url-encoded
}

extension GmailFullMessage {
    /// Extracts the plain text or HTML content from a GmailPayload
    func extractMessageBody() -> String? {
        // 1) Try to extract text/plain
        if let plain = findPart(in: payload, matching: "text/plain"),
            let raw = plain.body?.data,
            let decoded = raw.base64URLDecoded,
            let text = String(data: decoded, encoding: .utf8)
        {
            return text.htmlDecoded
        }

        // 2) Fallback to text/html and clean it with SwiftSoup
        if let htmlPart = findPart(in: payload, matching: "text/html"),
            let raw = htmlPart.body?.data,
            let decoded = raw.base64URLDecoded,
            let htmlString = String(data: decoded, encoding: .utf8)
        {
            do {
                let doc = try SwiftSoup.parse(htmlString)
                return try doc.text().htmlDecoded
            } catch {
                // If parsing fails, return the raw HTML string
                return htmlString
            }
        }

        // 3) No body found
        return nil
    }

    private func findPart(
        in payload: GmailPayload,
        matching mimeType: String
    ) -> GmailPayload? {
        if payload.mimeType == mimeType {
            return payload
        }
        if let children = payload.parts {
            for part in children {
                if let found = findPart(in: part, matching: mimeType) {
                    return found
                }
            }
        }
        return nil
    }
}
