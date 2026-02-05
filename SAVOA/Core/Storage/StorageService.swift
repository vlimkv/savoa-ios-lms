//
//  StorageService.swift
//  PelvicFloorApp
//
//  Created by 7Я on 04.12.2025.
//

import Foundation
import Security

protocol StorageServiceProtocol {
    func save<T: Codable>(_ value: T, forKey key: String)
    func load<T: Codable>(_ type: T.Type, forKey key: String) -> T?
    func remove(forKey key: String)
    func saveToKeychain(_ value: String, forKey key: String)
    func loadFromKeychain(forKey key: String) -> String?
    func removeFromKeychain(forKey key: String)
}

class StorageService: StorageServiceProtocol {
    static let shared = StorageService()
    
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - UserDefaults (for non-sensitive data)
    
    func save<T: Codable>(_ value: T, forKey key: String) {
        if let encoded = try? JSONEncoder().encode(value) {
            userDefaults.set(encoded, forKey: key)
        }
    }
    
    func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    func remove(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
    
    // MARK: - Keychain (for sensitive data like tokens)

    private var keychainService: String {
        Bundle.main.bundleIdentifier ?? "PelvicFloorApp"
    }

    func saveToKeychain(_ value: String, forKey key: String) {
        let data = Data(value.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func loadFromKeychain(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    func removeFromKeychain(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Storage Keys

extension StorageService {
    enum Keys {
        static let authToken = "auth_token"
        static let currentUser = "current_user"
        static let progress = "user_progress"
        static let journalEntries = "journal_entries"
        static let notificationSettings = "notification_settings"
        static let lastSyncDate = "last_sync_date"
    }
}
