import ErrorKit
import Foundation
import Noora

enum MessageProcessorError: Throwable, MyCatching {
    case caught(Error, function: String, line: Int)

    var userFriendlyMessage: String {
        switch self {
        case .caught(let error, let function, let line):
            return "\(ErrorKit.userFriendlyMessage(for: error)):\(function)-\(line)"
        }
    }
}

struct MessageProcessor {
    static func processEmails(progress: @escaping (Int, Int) -> Void)
    async throws(MessageProcessorError)
    {
        let (emails, assets) = try await MessageProcessorError.catch {
            async let emailsFetch = DatabaseClient.fetchUnprocessedEmails()
            async let assetsFetch = LunchMoneyClient.getAssets()
            return try await (emailsFetch, assetsFetch)
        }
        
        for (index, email) in emails.enumerated() {
            progress(index + 1, emails.count)
            try await processEmail(email, assets: assets)
        }
    }
    
    static func processEmail(
        _ email: RawEmail,
        assets: [LunchMoneyAsset]
    ) async throws(MessageProcessorError) {
        guard let payload = email.payload else {
            Noora().warning([.alert("Email with no payload: \(email.id)")])
            try await markProcessed(email, status: .noPayload)
            return
        }
        
        let ollamaTransaction = try await MessageProcessorError.catch {
            try await OllamaClient.extractTransaction(from: payload)
        }
        
        guard let type = ollamaTransaction.type, let amount = ollamaTransaction.amount else {
            Noora().warning([.alert("Non-transactional email: \(email.id)")])
            try await markProcessed(email, status: .needsReview)
            return
        }
        
        let asset = asset(for: ollamaTransaction, assets: assets)
        
        let debitAsNegative: Bool
        let multiplier: Decimal
        
        switch asset?.typeName {
        case .credit, .loan, .otherLiability:
            debitAsNegative = false
            multiplier = -1
        default:
            debitAsNegative = true
            multiplier = 1
        }
        
        let lunchMoneyTransaction = LunchMoneyTransaction(
            id: email.id,
            amount: amount * multiplier,
            date: email.createdAt,
            payee: ollamaTransaction.merchant,
            accountId: asset?.id,
            notes: email.id
        )
        
        try await MessageProcessorError.catch {
            try await LunchMoneyClient.syncTransaction(
                lunchMoneyTransaction,
                debitAsNegative: debitAsNegative
            )
        }
        
        try await markProcessed(email, status: .processed)
    }
    
    private static func markProcessed(_ email: RawEmail, status: RawEmail.Status) async throws(MessageProcessorError) {
        try await MessageProcessorError.catch {
            try await DatabaseClient.updateStatus(status, emailID: email.id)
            try await GoogleClient.markProcessed(email.id)
        }
    }
    
    private static func asset(
        for transaction: OllamaTransaction,
        assets: [LunchMoneyAsset]
    ) -> LunchMoneyAsset? {
        switch (transaction.account, transaction.institution) {
        case let (.some(account), _):
            return assets.first(where: { $0.name == account })
        case let (_, .some(institution)):
            let institutionAccounts = assets.filter {
                if let assetInstitution = $0.institutionName {
                    return assetInstitution.caseInsensitiveCompare(institution) == .orderedSame
                } else {
                    return false
                }
            }
            
            if institutionAccounts.count == 1 {
                return institutionAccounts.first
            }
            return nil
        default:
            return nil
        }
    }
}
