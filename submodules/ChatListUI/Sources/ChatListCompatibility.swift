import Foundation
import UIKit
import ObjectiveC.runtime
import Display
import ComponentFlow
import Postbox
import TelegramCore
import TelegramPresentationData
import AccountContext
import ContextUI
import ChatListHeaderComponent

private var chatListNodePinnedHeaderDisplayFractionUpdatedKey: UInt8 = 0
private var chatListNodePinnedScrollFractionKey: UInt8 = 0

extension ChatListNavigationBar.View {
    func openEmojiStatusSetup() {
    }
    
    func updateEdgeEffectForPinnedFraction(pinnedFraction: CGFloat, transition: ComponentTransition) {
    }
}

extension ChatListNode {
    var pinnedHeaderDisplayFractionUpdated: ((ContainedViewLayoutTransition) -> Void)? {
        get {
            return objc_getAssociatedObject(self, &chatListNodePinnedHeaderDisplayFractionUpdatedKey) as? ((ContainedViewLayoutTransition) -> Void)
        }
        set {
            objc_setAssociatedObject(self, &chatListNodePinnedHeaderDisplayFractionUpdatedKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    var pinnedScrollFraction: CGFloat {
        get {
            return CGFloat((objc_getAssociatedObject(self, &chatListNodePinnedScrollFractionKey) as? NSNumber)?.doubleValue ?? 0.0)
        }
        set {
            objc_setAssociatedObject(self, &chatListNodePinnedScrollFractionKey, NSNumber(value: Double(newValue)), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension ChatListNodeInteraction {
    func openSGAnnouncement(_ id: String, _ url: String, _ needAuth: Bool, _ permanent: Bool) {
        self.openUrl(url)
    }
}

extension PeerInfoScreen {
    public func tabBarItemContextActionRawUIView(sourceView: UIView, gesture: ContextGesture?) {
        guard let sourceView = sourceView as? ContextExtractedContentContainingView, let gesture else {
            return
        }
        self.tabBarItemContextAction(sourceView: sourceView, gesture: gesture)
    }
}

extension ChatListControllerImpl {
    func presentLeaveChannelConfirmation(peer: EnginePeer, nextCreator: EnginePeer, completion: @escaping (Bool) -> Void) {
        completion(true)
    }
}
