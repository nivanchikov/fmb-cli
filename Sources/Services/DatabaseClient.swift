import Foundation
import Supabase
import ErrorKit

enum DatabaseError: Throwable, MyCatching {
    case clientAuthFailed
    case caught(Error, function: String, line: Int)
    
    var userFriendlyMessage: String {
        switch self {
        case .clientAuthFailed:
            return "Client authentication failed. Please try again later."
        case let .caught(error, function, line):
            return "\(ErrorKit.userFriendlyMessage(for: error)):\(function)-\(line)"
        }
    }
}

struct DatabaseClient {
    private static let supabase: SupabaseClient = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        return SupabaseClient(
            supabaseURL: URL(string: Secrets.supabaseURL)!,
            supabaseKey: Secrets.supabaseKey,
            options: SupabaseClientOptions(
                db: SupabaseClientOptions.DatabaseOptions(
                    encoder: encoder,
                    decoder: decoder
                )
            )
        )
    }()
    
    private static func authenticateIfNeeded() async throws(DatabaseError) {
        if let session = supabase.auth.currentSession, !session.isExpired {
            return
        }
        
        try await DatabaseError.catch {
            try await supabase.auth.signIn(
                email: Secrets.supabaseServiceUserEmail,
                password: Secrets.supabaseServiceUserPassword
            )
        }
    }
    
    static var client: SupabaseClient {
        get async throws(DatabaseError) {
            try await authenticateIfNeeded()
            return supabase
        }
    }

    static func getRawEmailIDs(count: Int) async throws(DatabaseError) -> Set<String> {
        let response: [RawEmail.ID] = try await DatabaseError.catch {
            try await client
                .from("raw_emails")
                .select("id")
                .order("created_at", ascending: false)
                .limit(count)
                .execute()
                .value
        }
        
        return Set(response.map(\.id))
    }

    static func storeRawEmails(_ emails: [RawEmail]) async throws(DatabaseError) {
        try await DatabaseError.catch {
            try await client
                .from("raw_emails")
                .upsert(emails)
                .execute()
        }
    }
    
    static func updateStatus(_ status: RawEmail.Status, emailID: String) async throws(DatabaseError) {
        try await DatabaseError.catch {
            try await client
                .from("raw_emails")
                .update(["status": status.rawValue])
                .eq("id", value: emailID)
                .execute()
        }
    }
    
    static func fetchUnprocessedEmails() async throws(DatabaseError) -> [RawEmail] {
        try await DatabaseError.catch {
            try await client
                .from("raw_emails")
                .select()
                .filter("status", operator: "eq", value: RawEmail.Status.unprocessed.rawValue)
                .order("created_at", ascending: false)
                .execute()
                .value
        }
    }
}

protocol MyCatching {
    static func caught(_ error: Error, function: String, line: Int) -> Self
}

extension MyCatching {
    @discardableResult
    public static func `catch`<ReturnType>(
        function: String = #function, line: Int = #line,
       _ operation: () async throws -> ReturnType
    ) async throws(Self) -> ReturnType {
       do {
          return try await operation()
       } catch let error as Self {  // Avoid nesting if the error is already of the expected type
          throw error
       } catch {
          throw Self.caught(error, function: function, line: line)
       }
    }
    
    @discardableResult
    public static func `catch`<ReturnType>(
        function: String = #function, line: Int = #line,
       _ operation: () throws -> ReturnType
    ) throws(Self) -> ReturnType {
       do {
          return try operation()
       } catch let error as Self {  // Avoid nesting if the error is already of the expected type
          throw error
       } catch {
          throw Self.caught(error, function: function, line: line)
       }
    }
}
