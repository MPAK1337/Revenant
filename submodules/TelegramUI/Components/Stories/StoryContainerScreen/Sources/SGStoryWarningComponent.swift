import Foundation
import UIKit
import Display
import ComponentFlow
import TelegramCore
import TelegramPresentationData
import AccountContext

final class SGStoryWarningComponent: Component {
    typealias EnvironmentType = Empty
    
    let context: AccountContext
    let theme: PresentationTheme
    let strings: PresentationStrings
    let peer: EnginePeer?
    let isInStealthMode: Bool
    let action: () -> Void
    let close: () -> Void
    
    init(
        context: AccountContext,
        theme: PresentationTheme,
        strings: PresentationStrings,
        peer: EnginePeer?,
        isInStealthMode: Bool,
        action: @escaping () -> Void,
        close: @escaping () -> Void
    ) {
        self.context = context
        self.theme = theme
        self.strings = strings
        self.peer = peer
        self.isInStealthMode = isInStealthMode
        self.action = action
        self.close = close
    }
    
    static func ==(lhs: SGStoryWarningComponent, rhs: SGStoryWarningComponent) -> Bool {
        if lhs.context !== rhs.context {
            return false
        }
        if lhs.theme !== rhs.theme {
            return false
        }
        if lhs.strings !== rhs.strings {
            return false
        }
        if lhs.peer?.id != rhs.peer?.id {
            return false
        }
        if lhs.isInStealthMode != rhs.isInStealthMode {
            return false
        }
        return true
    }
    
    final class View: UIView {
        private let dimView = UIView()
        private let panelView = UIView()
        private let titleLabel = UILabel()
        private let textLabel = UILabel()
        private let continueButton = UIButton(type: .system)
        private let closeButton = UIButton(type: .system)
        
        private var component: SGStoryWarningComponent?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.dimView.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
            self.addSubview(self.dimView)
            
            self.panelView.layer.cornerRadius = 22.0
            self.panelView.layer.masksToBounds = true
            self.addSubview(self.panelView)
            
            self.titleLabel.numberOfLines = 0
            self.titleLabel.textAlignment = .center
            self.panelView.addSubview(self.titleLabel)
            
            self.textLabel.numberOfLines = 0
            self.textLabel.textAlignment = .center
            self.panelView.addSubview(self.textLabel)
            
            self.continueButton.layer.cornerRadius = 11.0
            self.continueButton.layer.masksToBounds = true
            self.continueButton.titleLabel?.font = Font.semibold(17.0)
            self.continueButton.addTarget(self, action: #selector(self.continuePressed), for: .touchUpInside)
            self.panelView.addSubview(self.continueButton)
            
            self.closeButton.titleLabel?.font = Font.regular(15.0)
            self.closeButton.addTarget(self, action: #selector(self.closePressed), for: .touchUpInside)
            self.panelView.addSubview(self.closeButton)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        @objc private func continuePressed() {
            self.component?.action()
        }
        
        @objc private func closePressed() {
            self.component?.close()
        }
        
        func animateIn() {
            self.dimView.alpha = 0.0
            self.panelView.alpha = 0.0
            self.panelView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
            UIView.animate(withDuration: 0.22, delay: 0.0, options: [.curveEaseOut]) {
                self.dimView.alpha = 1.0
                self.panelView.alpha = 1.0
                self.panelView.transform = .identity
            }
        }
        
        func animateOut(completion: @escaping () -> Void) {
            UIView.animate(withDuration: 0.18, delay: 0.0, options: [.curveEaseIn], animations: {
                self.dimView.alpha = 0.0
                self.panelView.alpha = 0.0
                self.panelView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
            }, completion: { _ in
                completion()
            })
        }
        
        func update(component: SGStoryWarningComponent, availableSize: CGSize, transition: ComponentTransition) -> CGSize {
            self.component = component
            
            self.dimView.frame = CGRect(origin: .zero, size: availableSize)
            self.panelView.backgroundColor = component.theme.actionSheet.opaqueItemBackgroundColor
            
            self.titleLabel.textColor = component.theme.actionSheet.primaryTextColor
            self.textLabel.textColor = component.theme.actionSheet.secondaryTextColor
            
            let title = component.isInStealthMode ? "Stealth Mode Is Enabled" : "Story View Warning"
            let text: String
            if component.isInStealthMode {
                text = "You are about to continue viewing stories while stealth mode is active. Swiftgram story actions may differ until migration is fully finished."
            } else {
                text = "Swiftgram story-specific warning UI is running in compatibility mode in this merged build. You can continue, but verify story actions carefully."
            }
            
            self.titleLabel.attributedText = NSAttributedString(
                string: title,
                font: Font.semibold(20.0),
                textColor: component.theme.actionSheet.primaryTextColor
            )
            self.textLabel.attributedText = NSAttributedString(
                string: text,
                font: Font.regular(15.0),
                textColor: component.theme.actionSheet.secondaryTextColor
            )
            
            self.continueButton.backgroundColor = component.theme.list.itemCheckColors.fillColor
            self.continueButton.setTitleColor(component.theme.list.itemCheckColors.foregroundColor, for: .normal)
            self.continueButton.setTitle("Continue", for: .normal)
            
            self.closeButton.setTitleColor(component.theme.list.itemAccentColor, for: .normal)
            self.closeButton.setTitle("Close", for: .normal)
            
            let panelWidth = min(availableSize.width - 32.0, 360.0)
            let titleSize = self.titleLabel.sizeThatFits(CGSize(width: panelWidth - 32.0, height: CGFloat.greatestFiniteMagnitude))
            let textSize = self.textLabel.sizeThatFits(CGSize(width: panelWidth - 32.0, height: CGFloat.greatestFiniteMagnitude))
            let buttonHeight: CGFloat = 50.0
            let closeHeight: CGFloat = 22.0
            let panelHeight = 24.0 + titleSize.height + 12.0 + textSize.height + 20.0 + buttonHeight + 12.0 + closeHeight + 20.0
            let panelFrame = CGRect(
                x: floor((availableSize.width - panelWidth) * 0.5),
                y: floor((availableSize.height - panelHeight) * 0.5),
                width: panelWidth,
                height: panelHeight
            )
            transition.setFrame(view: self.panelView, frame: panelFrame)
            
            self.titleLabel.frame = CGRect(x: 16.0, y: 24.0, width: panelWidth - 32.0, height: titleSize.height)
            self.textLabel.frame = CGRect(x: 16.0, y: self.titleLabel.frame.maxY + 12.0, width: panelWidth - 32.0, height: textSize.height)
            self.continueButton.frame = CGRect(x: 16.0, y: self.textLabel.frame.maxY + 20.0, width: panelWidth - 32.0, height: buttonHeight)
            self.closeButton.frame = CGRect(x: 16.0, y: self.continueButton.frame.maxY + 12.0, width: panelWidth - 32.0, height: closeHeight)
            
            return availableSize
        }
    }
    
    func makeView() -> View {
        return View(frame: CGRect())
    }
    
    func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, transition: transition)
    }
}
