import Foundation
import Security

public enum KeychainCommand {
    static let defaultService = "com.swiftswiss"

    public static func run(_ args: [String]) throws {
        var mode = "get"
        var service = defaultService
        var account: String?
        var password: String?

        var i = 0
        while i < args.count {
            switch args[i] {
            case "-mode", "-m":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("mode") }
                mode = args[i]
            case "-service":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("service") }
                service = args[i]
            case "-account":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("account") }
                account = args[i]
            case "-password":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("password") }
                password = args[i]
            case "-h", "--help":
                printHelp(); return
            default:
                throw SwiftSwissError.invalidOption("unknown option: \(args[i])")
            }
            i += 1
        }

        switch mode {
        case "set":
            guard let acct = account else { throw SwiftSwissError.missingArgument("-account") }
            let pass = password ?? readSecureInput(prompt: "Password: ")
            guard !pass.isEmpty else { throw SwiftSwissError.operationFailed("password cannot be empty") }
            try setItem(service: service, account: acct, password: pass)
            print("Stored password for \(acct) in service \(service)")

        case "get":
            guard let acct = account else { throw SwiftSwissError.missingArgument("-account") }
            let pass = try getItem(service: service, account: acct)
            print(pass)

        case "delete":
            guard let acct = account else { throw SwiftSwissError.missingArgument("-account") }
            try deleteItem(service: service, account: acct)
            print("Deleted \(acct) from service \(service)")

        case "list":
            let items = try listItems(service: service)
            if items.isEmpty {
                print("No items found for service: \(service)")
            } else {
                print("Accounts in \(service):")
                for item in items {
                    print("  \(item)")
                }
            }

        default:
            throw SwiftSwissError.invalidOption(
                "unknown mode: \(mode) (choices: set, get, delete, list)")
        }
    }

    public static func setItem(service: String, account: String, password: String) throws {
        // Delete any existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: Data(password.utf8),
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SwiftSwissError.operationFailed(
                "keychain set failed: \(secErrorMessage(status))")
        }
    }

    public static func getItem(service: String, account: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data,
              let password = String(data: data, encoding: .utf8) else {
            if status == errSecItemNotFound {
                throw SwiftSwissError.operationFailed("no keychain item found for account: \(account)")
            }
            throw SwiftSwissError.operationFailed(
                "keychain get failed: \(secErrorMessage(status))")
        }
        return password
    }

    public static func deleteItem(service: String, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SwiftSwissError.operationFailed(
                "keychain delete failed: \(secErrorMessage(status))")
        }
    }

    public static func listItems(service: String) throws -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound { return [] }
        guard status == errSecSuccess, let items = item as? [[String: Any]] else {
            throw SwiftSwissError.operationFailed(
                "keychain list failed: \(secErrorMessage(status))")
        }

        return items.compactMap { $0[kSecAttrAccount as String] as? String }.sorted()
    }

    static func secErrorMessage(_ status: OSStatus) -> String {
        if let msg = SecCopyErrorMessageString(status, nil) as? String {
            return msg
        }
        return "OSStatus \(status)"
    }

    static func printHelp() {
        print("""
        Usage: swiftswiss keychain -mode <mode> [options]

        Manage secrets in the macOS Keychain.

        Modes:
          set      Store a password
          get      Retrieve a password (default)
          delete   Delete a keychain item
          list     List accounts for a service

        Options:
          -mode, -m <mode>    Mode (default: get)
          -service <name>     Keychain service name (default: com.swiftswiss)
          -account <name>     Account name (required for set/get/delete)
          -password <pass>    Password for set mode (prompted securely if omitted)
          -h, --help          Show this help

        Frameworks: Security (Keychain Services)
        """)
    }
}
