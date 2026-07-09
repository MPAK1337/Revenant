import Foundation

/// UserNotesManager - Local storage for personal notes about users
/// Notes are stored ONLY on device, never synced to Telegram servers
public final class UserNotesManager {
    public static let shared = UserNotesManager()
    
    private enum Keys {
        static let notesPrefix = "UserNotes.note."
        static let updatedAtPrefix = "UserNotes.updatedAt."
    }
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Public API
    
    /// Get note for a specific user by their peerId
    public func getNote(for peerId: Int64) -> String? {
        return defaults.string(forKey: Keys.notesPrefix + String(peerId))
    }
    
    /// Set note for a specific user (pass nil or empty string to delete)
    public func setNote(_ note: String?, for peerId: Int64) {
        let key = Keys.notesPrefix + String(peerId)
        let dateKey = Keys.updatedAtPrefix + String(peerId)
        
        if let note = note, !note.isEmpty {
            defaults.set(note, forKey: key)
            defaults.set(Date(), forKey: dateKey)
        } else {
            defaults.removeObject(forKey: key)
            defaults.removeObject(forKey: dateKey)
        }
        
        notifyNoteChanged(peerId: peerId)
    }
    
    /// Check if user has a note
    public func hasNote(for peerId: Int64) -> Bool {
        guard let note = getNote(for: peerId) else { return false }
        return !note.isEmpty
    }
    
    /// Get last update date for a note
    public func getUpdatedAt(for peerId: Int64) -> Date? {
        return defaults.object(forKey: Keys.updatedAtPrefix + String(peerId)) as? Date
    }
    
    /// Get all peerIds that have notes
    public func getAllNotedPeerIds() -> [Int64] {
        let allKeys = defaults.dictionaryRepresentation().keys
        return allKeys
            .filter { $0.hasPrefix(Keys.notesPrefix) }
            .compactMap { key -> Int64? in
                let peerIdString = String(key.dropFirst(Keys.notesPrefix.count))
                return Int64(peerIdString)
            }
    }
    
    /// Delete all notes
    public func deleteAllNotes() {
        let peerIds = getAllNotedPeerIds()
        for peerId in peerIds {
            defaults.removeObject(forKey: Keys.notesPrefix + String(peerId))
            defaults.removeObject(forKey: Keys.updatedAtPrefix + String(peerId))
        }
        NotificationCenter.default.post(name: UserNotesManager.notesChangedNotification, object: nil)
    }
    
    /// Get notes count
    public var notesCount: Int {
        return getAllNotedPeerIds().count
    }
    
    // MARK: - Notification
    
    public static let notesChangedNotification = Notification.Name("UserNotesChanged")
    
    private func notifyNoteChanged(peerId: Int64) {
        NotificationCenter.default.post(
            name: UserNotesManager.notesChangedNotification,
            object: nil,
            userInfo: ["peerId": peerId]
        )
    }
    
    // MARK: - Init
    
    private init() {}
}
