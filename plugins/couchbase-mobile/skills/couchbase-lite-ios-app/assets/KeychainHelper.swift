//  KeychainHelper.swift
//  Secure storage for the App Services user's password.
//
//  Never store credentials in UserDefaults (unencrypted) or keep them in memory
//  after login. Storing them in the Keychain lets the app resume replication
//  after relaunch (e.g. the Settings "Reconnect" action) without re-login.
//
//  kSecAttrAccessibleWhenUnlockedThisDeviceOnly prevents iCloud backup and
//  cross-device migration of the credential.
//  Docs: https://developer.apple.com/documentation/security/keychain_services

import Foundation
import Security

enum KeychainHelper {

    /// Save (or overwrite) the password for a username.
    static func save(password: String, for username: String) {
        guard let data = password.data(using: .utf8) else { return }
        let query: [CFString: Any] = [
            kSecClass:          kSecClassGenericPassword,
            kSecAttrAccount:    username,
            kSecValueData:      data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)          // remove any existing entry first
        SecItemAdd(query as CFDictionary, nil)
    }

    /// Load the stored password for a username, if present.
    static func load(for username: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:      kSecClassGenericPassword,
            kSecAttrAccount: username,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Remove the stored password for a username (call on sign-out).
    static func delete(for username: String) {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: username
        ]
        SecItemDelete(query as CFDictionary)
    }
}
