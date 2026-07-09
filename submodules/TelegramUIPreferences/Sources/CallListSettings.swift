import Foundation
import TelegramCore
import SwiftSignalKit

public struct CallListSettings: Codable, Equatable {
    public var _showContactsTab: Bool?
    public var _showTab: Bool?

    public var showContactsTab: Bool {
        get {
            if let value = self._showContactsTab {
                return value
            } else {
                return true
            }
        }
        set {
            self._showContactsTab = newValue
        }
    }
    
    public static var defaultSettings: CallListSettings {
        return CallListSettings(showContactsTab: nil, showTab: nil)
    }
    
    public var showTab: Bool {
        get {
            if let value = self._showTab {
                return value
            } else {
                return true
            }
        } set {
            self._showTab = newValue
        }
    }
    
    public init(showContactsTab: Bool?, showTab: Bool?) {
        self._showContactsTab = showContactsTab
        self._showTab = showTab
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)

        if let value = try container.decodeIfPresent(Int32.self, forKey: "showContactsTab") {
            self._showContactsTab = value != 0
        }
        if let value = try container.decodeIfPresent(Int32.self, forKey: "showTab") {
            self._showTab = value != 0
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)

        if let showContactsTab = self._showContactsTab {
            try container.encode((showContactsTab ? 1 : 0) as Int32, forKey: "showContactsTab")
        } else {
            try container.encodeNil(forKey: "showContactsTab")
        }
        if let showTab = self._showTab {
            try container.encode((showTab ? 1 : 0) as Int32, forKey: "showTab")
        } else {
            try container.encodeNil(forKey: "showTab")
        }
    }
    
    public static func ==(lhs: CallListSettings, rhs: CallListSettings) -> Bool {
        return lhs._showContactsTab == rhs._showContactsTab && lhs._showTab == rhs._showTab
    }
    
    public func withUpdatedShowContactsTab(_ showContactsTab: Bool) -> CallListSettings {
        return CallListSettings(showContactsTab: showContactsTab, showTab: self._showTab)
    }
    
    public func withUpdatedShowTab(_ showTab: Bool) -> CallListSettings {
        return CallListSettings(showContactsTab: self._showContactsTab, showTab: showTab)
    }
}

public func updateCallListSettingsInteractively(accountManager: AccountManager<TelegramAccountManagerTypes>, _ f: @escaping (CallListSettings) -> CallListSettings) -> Signal<Void, NoError> {
    return accountManager.transaction { transaction -> Void in
        transaction.updateSharedData(ApplicationSpecificSharedDataKeys.callListSettings, { entry in
            let currentSettings: CallListSettings
            if let entry = entry?.get(CallListSettings.self) {
                currentSettings = entry
            } else {
                currentSettings = CallListSettings.defaultSettings
            }
            return SharedPreferencesEntry(f(currentSettings))
        })
    }
}
