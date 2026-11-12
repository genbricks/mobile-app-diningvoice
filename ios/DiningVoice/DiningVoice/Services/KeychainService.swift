import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()
    private let tokenKey = "io.genbricks.diningvoice.auth-token"
    private let userKey = "io.genbricks.diningvoice.user-data"

    private init() {}

    func saveToken(_ token: String) {
        save(key: tokenKey, data: Data(token.utf8))
    }

    func getToken() -> String? {
        guard let data = load(key: tokenKey) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func removeToken() {
        delete(key: tokenKey)
    }

    func saveUser(_ user: User) {
        guard let data = try? JSONEncoder().encode(user) else { return }
        save(key: userKey, data: data)
    }

    func getUser() -> User? {
        guard let data = load(key: userKey) else { return nil }
        return try? JSONDecoder().decode(User.self, from: data)
    }

    func removeUser() {
        delete(key: userKey)
    }

    func clearAll() {
        removeToken()
        removeUser()
    }

    private func save(key: String, data: Data) {
        delete(key: key)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
