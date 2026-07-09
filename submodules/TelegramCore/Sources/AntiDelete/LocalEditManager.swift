import Foundation

/// Менеджер для локального редактирования сообщений (только на стороне клиента)
/// Хранит редактирования в памяти - сбрасываются при перезапуске приложения
public final class LocalEditManager {
    
    public static let shared = LocalEditManager()
    
    // MARK: - Storage
    
    /// Хранилище редактирований: "peerId_messageId" -> новый текст
    private var edits: [String: String] = [:]
    private let lock = NSLock()
    
    private init() {}
    
    // MARK: - Public API
    
    /// Установить локальное редактирование для сообщения
    /// - Parameters:
    ///   - peerId: ID чата
    ///   - messageId: ID сообщения
    ///   - newText: Новый текст сообщения
    public func setLocalEdit(peerId: Int64, messageId: Int32, newText: String) {
        let key = makeKey(peerId: peerId, messageId: messageId)
        lock.lock()
        defer { lock.unlock() }
        edits[key] = newText
    }
    
    /// Получить локальное редактирование для сообщения
    /// - Parameters:
    ///   - peerId: ID чата
    ///   - messageId: ID сообщения
    /// - Returns: Отредактированный текст или nil если редактирования нет
    public func getLocalEdit(peerId: Int64, messageId: Int32) -> String? {
        let key = makeKey(peerId: peerId, messageId: messageId)
        lock.lock()
        defer { lock.unlock() }
        return edits[key]
    }
    
    /// Удалить локальное редактирование для сообщения
    /// - Parameters:
    ///   - peerId: ID чата
    ///   - messageId: ID сообщения
    public func removeLocalEdit(peerId: Int64, messageId: Int32) {
        let key = makeKey(peerId: peerId, messageId: messageId)
        lock.lock()
        defer { lock.unlock() }
        edits.removeValue(forKey: key)
    }
    
    /// Проверить наличие локального редактирования
    /// - Parameters:
    ///   - peerId: ID чата
    ///   - messageId: ID сообщения
    /// - Returns: true если есть редактирование
    public func hasLocalEdit(peerId: Int64, messageId: Int32) -> Bool {
        let key = makeKey(peerId: peerId, messageId: messageId)
        lock.lock()
        defer { lock.unlock() }
        return edits[key] != nil
    }
    
    /// Очистить все локальные редактирования
    public func clearAllEdits() {
        lock.lock()
        defer { lock.unlock() }
        edits.removeAll()
    }
    
    /// Количество активных редактирований
    public var editCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return edits.count
    }
    
    // MARK: - Private
    
    private func makeKey(peerId: Int64, messageId: Int32) -> String {
        return "\(peerId)_\(messageId)"
    }
}
