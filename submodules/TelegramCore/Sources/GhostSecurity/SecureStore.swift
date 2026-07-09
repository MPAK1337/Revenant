import Foundation
import CryptoKit
import Security
import LocalAuthentication

/// At-rest encryption for the fork's sensitive local stores (saved deleted
/// messages, edit history). Replaces the previous plaintext `UserDefaults`
/// persistence, which left recovered message content readable to anyone with
/// filesystem access.
///
/// Design notes:
///  - A single 256-bit AES key is generated once and kept in the Keychain with
///    `AfterFirstUnlockThisDeviceOnly` accessibility: device-bound, never in
///    iCloud/iTunes backups, and still usable for background message processing
///    once the device has been unlocked at least once since boot.
///  - Payloads are AES-GCM sealed (AEAD: confidential + tamper-evident) and
///    written as files under Application Support, excluded from backup and
///    tagged with file protection.
///  - Showing this data in the UI can be additionally gated behind Face ID via
///    `authenticateForViewing`. That gate is deliberately separate from the
///    storage key so it never blocks a background write.
public final class SecureStore {
    public static let shared = SecureStore()

    public enum StoreError: Error {
        case keychainFailure(OSStatus)
        case notReadable
    }

    private let service = "club.ghostgram.securestore"
    private let account = "master.key.v1"
    private let lock = NSLock()
    private var cachedKey: SymmetricKey?

    private lazy var baseDirectory: URL = {
        let fm = FileManager.default
        let support = (try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? fm.temporaryDirectory
        var dir = support.appendingPathComponent("GhostSecure", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true, attributes: [
                .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
            ])
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? dir.setResourceValues(values)
        }
        return dir
    }()

    private init() {}

    // MARK: - Key management

    private func key() throws -> SymmetricKey {
        lock.lock(); defer { lock.unlock() }
        if let cachedKey = self.cachedKey {
            return cachedKey
        }
        if let existing = try loadKey() {
            self.cachedKey = existing
            return existing
        }
        let newKey = SymmetricKey(size: .bits256)
        try storeKey(newKey)
        self.cachedKey = newKey
        return newKey
    }

    private func baseQuery() -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecUseDataProtectionKeychain as String: true
        ]
    }

    private func loadKey() throws -> SymmetricKey? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            guard let data = item as? Data else { throw StoreError.notReadable }
            return SymmetricKey(data: data)
        case errSecItemNotFound:
            return nil
        default:
            throw StoreError.keychainFailure(status)
        }
    }

    private func storeKey(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        var query = baseQuery()
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        query[kSecValueData as String] = keyData
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess || status == errSecDuplicateItem else {
            throw StoreError.keychainFailure(status)
        }
    }

    // MARK: - Encrypt / decrypt

    public func encrypt(_ data: Data) throws -> Data {
        let sealed = try AES.GCM.seal(data, using: try key())
        guard let combined = sealed.combined else { throw StoreError.notReadable }
        return combined
    }

    public func decrypt(_ data: Data) throws -> Data {
        let box = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(box, using: try key())
    }

    // MARK: - File-backed Codable storage

    private func fileURL(forKey storeKey: String) -> URL {
        let safe = storeKey.replacingOccurrences(of: "/", with: "_")
        return baseDirectory.appendingPathComponent(safe).appendingPathExtension("ghost")
    }

    private func write(_ ciphertext: Data, to url: URL) throws {
        try ciphertext.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    public func setSecure<T: Encodable>(_ value: T, forKey storeKey: String) throws {
        let plaintext = try JSONEncoder().encode(value)
        try write(try encrypt(plaintext), to: fileURL(forKey: storeKey))
    }

    public func getSecure<T: Decodable>(_ type: T.Type, forKey storeKey: String) throws -> T? {
        let url = fileURL(forKey: storeKey)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let plaintext = try decrypt(try Data(contentsOf: url))
        return try JSONDecoder().decode(type, from: plaintext)
    }

    public func removeSecure(forKey storeKey: String) {
        try? FileManager.default.removeItem(at: fileURL(forKey: storeKey))
    }

    // MARK: - One-time migration from plaintext UserDefaults

    /// Moves a previously plaintext `Data` blob out of `UserDefaults` into the
    /// encrypted store, then wipes the plaintext copy. Safe to call repeatedly:
    /// it no-ops once the encrypted file exists.
    public func migratePlaintextIfNeeded(userDefaultsKey: String, storeKey: String, defaults: UserDefaults = .standard) {
        guard !FileManager.default.fileExists(atPath: fileURL(forKey: storeKey).path) else { return }
        guard let legacy = defaults.data(forKey: userDefaultsKey) else { return }
        do {
            try write(try encrypt(legacy), to: fileURL(forKey: storeKey))
            defaults.removeObject(forKey: userDefaultsKey)
        } catch {
            // Leave the legacy copy untouched on failure so no data is lost.
        }
    }

    // MARK: - Biometric gate for viewing (separate from the storage key)

    /// Prompts Face ID / Touch ID (with device-passcode fallback) before the UI
    /// reveals recovered content. Does not touch the storage key.
    public func authenticateForViewing(reason: String, completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        let policy: LAPolicy = .deviceOwnerAuthentication
        // Pass nil for the error out-param: under -warnings-as-errors an unread
        // `var error` would be flagged as written-but-never-read.
        guard context.canEvaluatePolicy(policy, error: nil) else {
            completion(false)
            return
        }
        context.evaluatePolicy(policy, localizedReason: reason) { success, _ in
            DispatchQueue.main.async { completion(success) }
        }
    }
}
