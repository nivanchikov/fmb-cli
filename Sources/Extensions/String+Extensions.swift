import Foundation

extension String {
    func cleanedUp() -> String {
        // 1) Normalize all \r\n or \r into \n
        let normalized =
            self
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        // 2) Split on newlines, trim whitespace, drop empty lines
        let lines =
            normalized
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        // 3) Re-join with single newlines (or use " " if you want a single paragraph)
        return lines.joined(separator: "\n")
    }

    /// Decodes a URL-safe Base64 string into Data
    var base64URLDecoded: Data? {
        var s =
            self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let padLength = 4 - (s.count % 4)

        if padLength < 4 {
            s += String(repeating: "=", count: padLength)
        }
        return Data(base64Encoded: s)
    }

    var htmlDecoded: String {
        guard let data = self.data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]
        // If it succeeds, `attributed.string` is the plain‐text with entities decoded.
        if let attributed = try? NSAttributedString(
            data: data,
            options: options,
            documentAttributes: nil)
        {
            return attributed.string
        }
        return self
    }
}
