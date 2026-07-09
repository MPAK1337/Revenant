import Foundation


/// Manages edit history for messages
/// GHOSTGRAM: Stores original message text before edits for history viewing
public final class EditHistoryManager {
    public static let shared = EditHistoryManager()
    
    private let historyKey = "ghostgram_edit_history"
    private var editHistory: [String: [EditRecord]] = [:]
    private let lock = NSLock()
    
    public struct EditRecord: Codable, Equatable {
        public let text: String
        public let editDate: Int32
        
        public init(text: String, editDate: Int32) {
            self.text = text
            self.editDate = editDate
        }
    }
    
    private init() {
        loadHistory()
    }
    
    /// Creates a unique key for message identification
    private func messageKey(peerId: Int64, messageId: Int32) -> String {
        return "\(peerId)_\(messageId)"
    }
    
    /// Saves the original text before an edit
    /// Call this BEFORE the message is updated with new text
    public func saveOriginalText(peerId: Int64, messageId: Int32, originalText: String, editDate: Int32) {
        lock.lock()
        defer { lock.unlock() }
        
        let key = messageKey(peerId: peerId, messageId: messageId)
        
        // Don't save empty text
        guard !originalText.isEmpty else { return }
        
        // Get existing history or create new
        var history = editHistory[key] ?? []
        
        // Check if this exact text already exists (avoid duplicates)
        if history.last?.text != originalText {
            let record = EditRecord(text: originalText, editDate: editDate)
            history.append(record)
            editHistory[key] = history
            saveHistory()
        }
    }
    
    /// Gets edit history for a message
    public func getEditHistory(peerId: Int64, messageId: Int32) -> [EditRecord] {
        lock.lock()
        defer { lock.unlock() }
        
        let key = messageKey(peerId: peerId, messageId: messageId)
        return editHistory[key] ?? []
    }
    
    /// Checks if a message has edit history
    public func hasEditHistory(peerId: Int64, messageId: Int32) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        let key = messageKey(peerId: peerId, messageId: messageId)
        return !(editHistory[key]?.isEmpty ?? true)
    }
    
    /// Clears history for a specific message
    public func clearHistory(peerId: Int64, messageId: Int32) {
        lock.lock()
        defer { lock.unlock() }
        
        let key = messageKey(peerId: peerId, messageId: messageId)
        editHistory.removeValue(forKey: key)
        saveHistory()
    }
    
    /// Clears all edit history
    public func clearAllHistory() {
        lock.lock()
        defer { lock.unlock() }
        
        editHistory.removeAll()
        saveHistory()
    }
    
    // MARK: - Persistence
    
    private func saveHistory() {
        // Pre-edit originals are sensitive; store them encrypted at rest.
        try? SecureStore.shared.setSecure(editHistory, forKey: historyKey)
    }

    private func loadHistory() {
        SecureStore.shared.migratePlaintextIfNeeded(userDefaultsKey: historyKey, storeKey: historyKey)
        do {
            editHistory = try SecureStore.shared.getSecure([String: [EditRecord]].self, forKey: historyKey) ?? [:]
        } catch {
            editHistory = [:]
        }
    }
}
