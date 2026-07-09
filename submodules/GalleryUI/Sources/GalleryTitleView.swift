import Foundation
import UIKit
import AsyncDisplayKit
import Display
import Postbox
import TelegramCore
import TelegramPresentationData
import TelegramStringFormatting
import AccountContext

private let titleFont = Font.medium(15.0)
private let dateFont = Font.regular(14.0)

public final class GalleryTitleView: UIView, NavigationBarTitleView {    
    public struct Content {
        let message: EngineMessage?
        let title: String?
        let action: (() -> Void)?
        
        init(message: EngineMessage, title: String?, action: (() -> Void)?) {
            self.message = message
            self.title = title
            self.action = action
        }
    }
    
    private let authorNameNode: ASTextNode
    private let dateNode: ASTextNode
    private var context: AccountContext?
    private var presentationDataValue: PresentationData?
    private var contentAction: (() -> Void)?
    private var tapRecognizer: UITapGestureRecognizer?
    
    public var requestUpdate: ((ContainedViewLayoutTransition) -> Void)?
    
    override init(frame: CGRect) {
        self.authorNameNode = ASTextNode()
        self.authorNameNode.displaysAsynchronously = false
        self.authorNameNode.maximumNumberOfLines = 1
        
        self.dateNode = ASTextNode()
        self.dateNode.displaysAsynchronously = false
        self.dateNode.maximumNumberOfLines = 1
        
        super.init(frame: frame)
        
        self.addSubnode(self.authorNameNode)
        self.addSubnode(self.dateNode)
    }
    
    convenience init(context: AccountContext, presentationData: PresentationData) {
        self.init(frame: CGRect())
        self.context = context
        self.presentationDataValue = presentationData
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setMessage(_ message: Message, presentationData: PresentationData, accountPeerId: PeerId) {
        let authorNameText = stringForFullAuthorName(message: EngineMessage(message), strings: presentationData.strings, nameDisplayOrder: presentationData.nameDisplayOrder, accountPeerId: accountPeerId).joined(separator: " → ")
        let dateText = humanReadableStringForTimestamp(strings: presentationData.strings, dateTimeFormat: presentationData.dateTimeFormat, timestamp: message.timestamp).string
        
        self.authorNameNode.attributedText = NSAttributedString(string: authorNameText, font: titleFont, textColor: .white)
        self.dateNode.attributedText = NSAttributedString(string: dateText, font: dateFont, textColor: .white)
    }
    
    func setContent(content: Content?) {
        self.contentAction = content?.action
        
        if self.tapRecognizer == nil {
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.contentTapped))
            self.addGestureRecognizer(tapRecognizer)
            self.tapRecognizer = tapRecognizer
        }
        self.tapRecognizer?.isEnabled = content?.action != nil
        
        if let content, let message = content.message, let context = self.context, let presentationData = self.presentationDataValue {
            self.setMessage(message._asMessage(), presentationData: presentationData, accountPeerId: context.account.peerId)
            if let title = content.title {
                self.authorNameNode.attributedText = NSAttributedString(string: title, font: titleFont, textColor: .white)
            }
        } else if let title = content?.title {
            self.authorNameNode.attributedText = NSAttributedString(string: title, font: titleFont, textColor: .white)
            self.dateNode.attributedText = nil
        } else {
            self.authorNameNode.attributedText = nil
            self.dateNode.attributedText = nil
        }
        
        self.requestUpdate?(.immediate)
    }
    
    @objc private func contentTapped() {
        self.contentAction?()
    }
    
    public func updateLayout(availableSize: CGSize, transition: ContainedViewLayoutTransition) -> CGSize {
        let size = availableSize
        
        let leftInset: CGFloat = 0.0
        let rightInset: CGFloat = 0.0
        
        let authorNameSize = self.authorNameNode.measure(CGSize(width: max(1.0, size.width - 8.0 * 2.0 - leftInset - rightInset), height: CGFloat.greatestFiniteMagnitude))
        let dateSize = self.dateNode.measure(CGSize(width: max(1.0, size.width - 8.0 * 2.0), height: CGFloat.greatestFiniteMagnitude))
        
        if authorNameSize.height.isZero {
            self.dateNode.frame = CGRect(origin: CGPoint(x: floor((size.width - dateSize.width) / 2.0), y: floor((size.height - dateSize.height) / 2.0)), size: dateSize)
        } else {
            let labelsSpacing: CGFloat = 0.0
            self.authorNameNode.frame = CGRect(origin: CGPoint(x: floor((size.width - authorNameSize.width) / 2.0), y: floor((size.height - dateSize.height - authorNameSize.height - labelsSpacing) / 2.0)), size: authorNameSize)
            self.dateNode.frame = CGRect(origin: CGPoint(x: floor((size.width - dateSize.width) / 2.0), y: floor((size.height - dateSize.height - authorNameSize.height - labelsSpacing) / 2.0) + authorNameSize.height + labelsSpacing), size: dateSize)
        }
        
        return availableSize
    }
    
    public func animateLayoutTransition() {
        
    }
}
