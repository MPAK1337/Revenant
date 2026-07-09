// MARK: Swiftgram
import SGLogging
import SGAppGroupIdentifier
import SGSimpleSettings
import SwiftSignalKit
import TelegramUIPreferences
import AccountContext
import Postbox
import Foundation

extension SharedAccountContextImpl {
    // MARK: Swiftgram
    func performSGUISettingsMigrationIfNecessary() {
        if self.didPerformSGUISettingsMigration {
            return
        }
        self.didPerformSGUISettingsMigration = true
    }
}
