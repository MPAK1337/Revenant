import Foundation
import UIKit
import ComponentFlow
import ChatListTitleView
import TelegramPresentationData
import Display
import MoreHeaderButton

public final class NavigationButtonComponentEnvironment: Equatable {
    public let theme: PresentationTheme
    
    public init(theme: PresentationTheme) {
        self.theme = theme
    }
    
    public static func ==(lhs: NavigationButtonComponentEnvironment, rhs: NavigationButtonComponentEnvironment) -> Bool {
        if lhs.theme != rhs.theme {
            return false
        }
        return true
    }
}

public final class NavigationButtonComponent: Component {
    public typealias EnvironmentType = NavigationButtonComponentEnvironment
    
    public enum Content: Equatable {
        case text(title: String, isBold: Bool)
        case more
        case icon(imageName: String)
        case proxy(status: ChatTitleProxyStatus)
        /// Liquid glass avatar button for account switching.
        /// peerId is used as a diff key; avatarImage is the rendered avatar.
        case avatar(peerId: String, avatarImage: UIImage?)
        
        public static func ==(lhs: Content, rhs: Content) -> Bool {
            switch (lhs, rhs) {
            case let (.text(lt, lb), .text(rt, rb)):
                return lt == rt && lb == rb
            case (.more, .more):
                return true
            case let (.icon(l), .icon(r)):
                return l == r
            case let (.proxy(l), .proxy(r)):
                return l == r
            case let (.avatar(lId, _), .avatar(rId, _)):
                // Re-render when peerId changes; image updates are handled by the view itself
                return lId == rId
            default:
                return false
            }
        }
    }
    
    public let content: Content
    public let pressed: (UIView) -> Void
    public let contextAction: ((UIView, ContextGesture?) -> Void)?
    
    public init(
        content: Content,
        pressed: @escaping (UIView) -> Void,
        contextAction: ((UIView, ContextGesture?) -> Void)? = nil
    ) {
        self.content = content
        self.pressed = pressed
        self.contextAction = contextAction
    }
    
    public static func ==(lhs: NavigationButtonComponent, rhs: NavigationButtonComponent) -> Bool {
        if lhs.content != rhs.content {
            return false
        }
        return true
    }
    
    public final class View: HighlightTrackingButton {
        private var textView: ImmediateTextView?
        
        private var iconView: UIImageView?
        private var iconImageName: String?
        
        private var proxyNode: ChatTitleProxyNode?
        
        private var moreButton: MoreHeaderButton?
        
        // MARK: - Liquid Glass Avatar
        private var avatarContainerView: UIView?
        private var avatarBlurView: UIVisualEffectView?
        private var avatarImageView: UIImageView?
        private var avatarBorderLayer: CAShapeLayer?
        
        private var component: NavigationButtonComponent?
        private var theme: PresentationTheme?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.addTarget(self, action: #selector(self.pressed), for: .touchUpInside)
            
            self.highligthedChanged = { [weak self] highlighted in
                guard let self else {
                    return
                }
                let alpha: CGFloat = highlighted ? 0.55 : 1.0
                self.textView?.alpha = alpha
                self.proxyNode?.alpha = alpha
                self.iconView?.alpha = alpha
                self.avatarContainerView?.alpha = alpha
                if !highlighted {
                    let animateAlpha = { (layer: CALayer?) in
                        let anim = CABasicAnimation(keyPath: "opacity")
                        anim.fromValue = 0.55
                        anim.toValue = 1.0
                        anim.duration = 0.2
                        layer?.add(anim, forKey: "opacity")
                    }
                    animateAlpha(self.textView?.layer)
                    animateAlpha(self.proxyNode?.layer)
                    animateAlpha(self.iconView?.layer)
                    animateAlpha(self.avatarContainerView?.layer)
                }
            }
        }
        
        required public init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        @objc private func pressed() {
            self.component?.pressed(self)
        }
        
        // MARK: - Liquid glass avatar setup
        
        private func setupAvatarViewsIfNeeded() {
            guard avatarContainerView == nil else { return }
            
            // Container holds blur + image
            let container = UIView()
            container.isUserInteractionEnabled = false
            container.clipsToBounds = true
            
            // Blur background — liquid glass effect
            let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.isUserInteractionEnabled = false
            container.addSubview(blurView)
            
            // Avatar image on top of blur
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.isUserInteractionEnabled = false
            imageView.clipsToBounds = true
            container.addSubview(imageView)
            
            self.addSubview(container)
            self.avatarContainerView = container
            self.avatarBlurView = blurView
            self.avatarImageView = imageView
            
            // Subtle glass ring border
            let borderLayer = CAShapeLayer()
            borderLayer.fillColor = UIColor.clear.cgColor
            borderLayer.strokeColor = UIColor.white.withAlphaComponent(0.22).cgColor
            borderLayer.lineWidth = 1.5
            container.layer.addSublayer(borderLayer)
            self.avatarBorderLayer = borderLayer
        }
        
        private func removeAvatarViews() {
            avatarContainerView?.removeFromSuperview()
            avatarContainerView = nil
            avatarBlurView = nil
            avatarImageView = nil
            avatarBorderLayer = nil
        }
        
        func update(component: NavigationButtonComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<NavigationButtonComponentEnvironment>, transition: ComponentTransition) -> CGSize {
            self.component = component
            
            let theme = environment[NavigationButtonComponentEnvironment.self].value.theme
            var themeUpdated = false
            if self.theme !== theme {
                self.theme = theme
                themeUpdated = true
            }
            
            var textString: NSAttributedString?
            var imageName: String?
            var proxyStatus: ChatTitleProxyStatus?
            var isMore: Bool = false
            var avatarContent: (peerId: String, image: UIImage?)? = nil
            
            switch component.content {
            case let .text(title, isBold):
                textString = NSAttributedString(string: title, font: isBold ? Font.bold(17.0) : Font.medium(17.0), textColor: theme.chat.inputPanel.panelControlColor)
            case .more:
                isMore = true
            case let .icon(imageNameValue):
                imageName = imageNameValue
            case let .proxy(status):
                proxyStatus = status
            case let .avatar(peerId, image):
                avatarContent = (peerId, image)
            }
            
            var size = CGSize(width: 0.0, height: availableSize.height)
            
            // MARK: Text
            if let textString = textString {
                let textView: ImmediateTextView
                if let current = self.textView {
                    textView = current
                } else {
                    textView = ImmediateTextView()
                    textView.isUserInteractionEnabled = false
                    self.textView = textView
                    self.addSubview(textView)
                }
                
                textView.attributedText = textString
                let textSize = textView.updateLayout(availableSize)
                let textInset: CGFloat = 12.0
                size.width = max(44.0, textSize.width + textInset * 2.0)
                
                textView.frame = CGRect(origin: CGPoint(x: floor((size.width - textSize.width) / 2.0), y: floor((availableSize.height - textSize.height) / 2.0)), size: textSize)
                removeAvatarViews()
            } else if let textView = self.textView {
                self.textView = nil
                textView.removeFromSuperview()
            }
            
            // MARK: Icon
            if let imageName = imageName {
                let iconView: UIImageView
                if let current = self.iconView {
                    iconView = current
                } else {
                    iconView = UIImageView()
                    iconView.isUserInteractionEnabled = false
                    self.iconView = iconView
                    self.addSubview(iconView)
                }
                if self.iconImageName != imageName || themeUpdated {
                    self.iconImageName = imageName
                    iconView.image = generateTintedImage(image: UIImage(bundleImageName: imageName), color: theme.chat.inputPanel.panelControlColor)
                }
                
                if let iconSize = iconView.image?.size {
                    size.width = 44.0
                    iconView.frame = CGRect(origin: CGPoint(x: floor((size.width - iconSize.width) / 2.0), y: floor((availableSize.height - iconSize.height) / 2.0)), size: iconSize)
                }
                removeAvatarViews()
            } else if let iconView = self.iconView {
                self.iconView = nil
                iconView.removeFromSuperview()
                self.iconImageName = nil
            }
            
            // MARK: Proxy
            if let proxyStatus = proxyStatus {
                let proxyNode: ChatTitleProxyNode
                if let current = self.proxyNode {
                    proxyNode = current
                } else {
                    proxyNode = ChatTitleProxyNode(theme: theme)
                    proxyNode.isUserInteractionEnabled = false
                    self.proxyNode = proxyNode
                    self.addSubnode(proxyNode)
                }
                
                let proxySize = CGSize(width: 30.0, height: 30.0)
                size.width = 44.0
                
                proxyNode.theme = theme
                proxyNode.status = proxyStatus
                proxyNode.frame = CGRect(origin: CGPoint(x: floor((size.width - proxySize.width) / 2.0), y: floor((availableSize.height - proxySize.height) / 2.0)), size: proxySize)
                removeAvatarViews()
            } else if let proxyNode = self.proxyNode {
                self.proxyNode = nil
                proxyNode.removeFromSupernode()
            }
            
            // MARK: More
            if isMore {
                let moreButton: MoreHeaderButton
                if let current = self.moreButton, !themeUpdated {
                    moreButton = current
                } else {
                    if let moreButton = self.moreButton {
                        moreButton.removeFromSupernode()
                        self.moreButton = nil
                    }
                    
                    moreButton = MoreHeaderButton(color: theme.chat.inputPanel.panelControlColor)
                    moreButton.isUserInteractionEnabled = true
                    moreButton.setContent(.more(MoreHeaderButton.optionsCircleImage(color: theme.chat.inputPanel.panelControlColor)))
                    moreButton.onPressed = { [weak self] in
                        guard let self, let component = self.component else {
                            return
                        }
                        self.moreButton?.play()
                        component.pressed(self)
                    }
                    moreButton.contextAction = { [weak self] sourceNode, gesture in
                        guard let self, let component = self.component else {
                            return
                        }
                        self.moreButton?.play()
                        component.contextAction?(self, gesture)
                    }
                    self.moreButton = moreButton
                    self.addSubnode(moreButton)
                }
                
                let buttonSize = CGSize(width: 44.0, height: 44.0)
                size.width = 44.0
                
                moreButton.setContent(.more(MoreHeaderButton.optionsCircleImage(color: theme.rootController.navigationBar.buttonColor)))
                moreButton.frame = CGRect(origin: CGPoint(x: floor((size.width - buttonSize.width) / 2.0), y: floor((size.height - buttonSize.height) / 2.0)), size: buttonSize)
                removeAvatarViews()
            } else if let moreButton = self.moreButton {
                self.moreButton = nil
                moreButton.removeFromSupernode()
            }
            
            // MARK: Liquid Glass Avatar
            if let (_, image) = avatarContent {
                setupAvatarViewsIfNeeded()
                
                let avatarDiameter: CGFloat = 28.0
                size.width = 44.0
                
                let containerRect = CGRect(
                    x: floor((size.width - avatarDiameter) / 2.0),
                    y: floor((availableSize.height - avatarDiameter) / 2.0),
                    width: avatarDiameter,
                    height: avatarDiameter
                )
                
                avatarContainerView?.frame = containerRect
                avatarContainerView?.layer.cornerRadius = avatarDiameter / 2.0
                
                avatarBlurView?.frame = CGRect(origin: .zero, size: containerRect.size)
                
                if let image = image {
                    avatarImageView?.image = image
                    avatarImageView?.frame = CGRect(origin: .zero, size: containerRect.size)
                    avatarImageView?.backgroundColor = nil
                } else {
                    avatarImageView?.image = nil
                    // Fallback: solid tinted background when no photo
                    avatarImageView?.frame = CGRect(origin: .zero, size: containerRect.size)
                    avatarImageView?.backgroundColor = theme.list.itemAccentColor.withAlphaComponent(0.35)
                }
                
                // Update border ring path
                let borderPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: containerRect.size).insetBy(dx: 0.75, dy: 0.75), cornerRadius: avatarDiameter / 2.0)
                avatarBorderLayer?.path = borderPath.cgPath
                avatarBorderLayer?.frame = CGRect(origin: .zero, size: containerRect.size)
                
            } else if avatarContent == nil && avatarContainerView != nil {
                removeAvatarViews()
            }
            
            return size
        }
    }
    
    public func makeView() -> View {
        return View(frame: CGRect())
    }
    
    public func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<NavigationButtonComponentEnvironment>, transition: ComponentTransition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}
