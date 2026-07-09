import Foundation
import UIKit
import Display
import SwiftSignalKit
import AccountContext
import TelegramPresentationData

public func makeContextController(
    context: AccountContext? = nil,
    presentationData: PresentationData,
    source: ContextContentSource,
    items: Signal<ContextController.Items, NoError>,
    recognizer: TapLongTapOrDoubleTapGestureRecognizer? = nil,
    gesture: ContextGesture? = nil,
    workaroundUseLegacyImplementation: Bool = false,
    disableScreenshots: Bool = false,
    hideReactionPanelTail: Bool = false
) -> ContextController {
    return ContextController(
        context: context,
        presentationData: presentationData,
        source: source,
        items: items,
        recognizer: recognizer,
        gesture: gesture,
        workaroundUseLegacyImplementation: workaroundUseLegacyImplementation,
        disableScreenshots: disableScreenshots,
        hideReactionPanelTail: hideReactionPanelTail
    )
}

public func makePeekController(
    presentationData: PresentationData,
    content: PeekControllerContent,
    sourceView: @escaping () -> (UIView, CGRect)?,
    activateImmediately: Bool = false
) -> PeekController {
    return PeekController(
        presentationData: presentationData,
        content: content,
        sourceView: sourceView,
        activateImmediately: activateImmediately
    )
}

public func makePinchController(
    sourceNode: PinchSourceContainerNode,
    disableScreenshots: Bool = false,
    getContentAreaInScreenSpace: @escaping () -> CGRect
) -> PinchController {
    return PinchController(
        sourceNode: sourceNode,
        disableScreenshots: disableScreenshots,
        getContentAreaInScreenSpace: getContentAreaInScreenSpace
    )
}

public func makeContextControllerActionsStackNode(
    context: AccountContext?,
    getController: @escaping () -> ContextControllerProtocol?,
    requestDismiss: @escaping (ContextMenuActionResult) -> Void,
    requestUpdate: @escaping (ContainedViewLayoutTransition) -> Void
) -> ContextControllerActionsStackNode {
    return ContextControllerActionsStackNode(
        context: context,
        getController: getController,
        requestDismiss: requestDismiss,
        requestUpdate: requestUpdate
    )
}

public func makeContextControllerActionsListStackItem(
    id: AnyHashable?,
    items: [ContextMenuItem],
    reactionItems: ContextControllerReactionItems?,
    previewReaction: ContextControllerPreviewReaction?,
    tip: ContextController.Tip?,
    tipSignal: Signal<ContextController.Tip?, NoError>?,
    dismissed: (() -> Void)?
) -> ContextControllerActionsListStackItem {
    return ContextControllerActionsListStackItem(
        id: id,
        items: items,
        reactionItems: reactionItems,
        previewReaction: previewReaction,
        tip: tip,
        tipSignal: tipSignal,
        dismissed: dismissed
    )
}
