import Foundation
import UIKit
import Display
import ComponentFlow
import TelegramCore
import TelegramPresentationData
import ViewControllerComponent
import SheetComponent
import BundleIconComponent
import BalancedTextComponent
import MultilineTextComponent
import ButtonComponent
import GiftItemComponent
import AccountContext
import GlassBarButtonComponent

private func giftCraftRibbonColor(for gift: StarGift.UniqueGift) -> GiftItemComponent.Ribbon.Color {
    for attribute in gift.attributes {
        if case let .backdrop(_, _, innerColor, outerColor, _, _, _) = attribute {
            return .custom(outerColor, innerColor)
        }
    }
    return .blue
}

private final class GiftCraftSheetContent: CombinedComponent {
    typealias EnvironmentType = ViewControllerComponentContainer.Environment
    
    let context: AccountContext
    let gift: StarGift.UniqueGift
    let dismiss: () -> Void
    
    init(
        context: AccountContext,
        gift: StarGift.UniqueGift,
        dismiss: @escaping () -> Void
    ) {
        self.context = context
        self.gift = gift
        self.dismiss = dismiss
    }
    
    static func ==(lhs: GiftCraftSheetContent, rhs: GiftCraftSheetContent) -> Bool {
        if lhs.context !== rhs.context {
            return false
        }
        if lhs.gift != rhs.gift {
            return false
        }
        return true
    }
    
    static var body: Body {
        let closeButton = Child(GlassBarButtonComponent.self)
        let title = Child(BalancedTextComponent.self)
        let text = Child(MultilineTextComponent.self)
        let gift = Child(GiftItemComponent.self)
        let button = Child(ButtonComponent.self)
        
        return { context in
            let environment = context.environment[EnvironmentType.self]
            let component = context.component
            let theme = environment.theme
            
            var contentSize = CGSize(width: context.availableSize.width, height: 18.0)
            
            let closeButton = closeButton.update(
                component: GlassBarButtonComponent(
                    size: CGSize(width: 40.0, height: 40.0),
                    backgroundColor: theme.rootController.navigationBar.glassBarButtonBackgroundColor,
                    isDark: theme.overallDarkAppearance,
                    state: .generic,
                    component: AnyComponentWithIdentity(
                        id: "close",
                        component: AnyComponent(
                            BundleIconComponent(
                                name: "Navigation/Close",
                                tintColor: theme.chat.inputPanel.panelControlColor
                            )
                        )
                    ),
                    action: { _ in
                        component.dismiss()
                    }
                ),
                availableSize: CGSize(width: 40.0, height: 40.0),
                transition: context.transition
            )
            context.add(closeButton.position(CGPoint(x: environment.safeInsets.left + 16.0 + closeButton.size.width / 2.0, y: 36.0)))
            
            let title = title.update(
                component: BalancedTextComponent(
                    text: .plain(NSAttributedString(string: "Gift Crafting", font: Font.semibold(17.0), textColor: theme.actionSheet.primaryTextColor)),
                    horizontalAlignment: .center,
                    maximumNumberOfLines: 1,
                    lineSpacing: 0.1
                ),
                availableSize: CGSize(width: context.availableSize.width - 96.0, height: context.availableSize.height),
                transition: context.transition
            )
            context.add(title.position(CGPoint(x: context.availableSize.width / 2.0, y: contentSize.height + title.size.height / 2.0)))
            contentSize.height += title.size.height + 16.0
            
            let giftSize = CGSize(width: 140.0, height: 140.0)
            let gift = gift.update(
                component: GiftItemComponent(
                    context: component.context,
                    style: .glass,
                    theme: theme,
                    strings: environment.strings,
                    subject: .uniqueGift(gift: component.gift, price: nil),
                    ribbon: GiftItemComponent.Ribbon(
                        text: "#\(component.gift.number)",
                        font: .monospaced,
                        color: giftCraftRibbonColor(for: component.gift)
                    ),
                    mode: .grid
                ),
                availableSize: giftSize,
                transition: context.transition
            )
            context.add(gift.position(CGPoint(x: context.availableSize.width / 2.0, y: contentSize.height + gift.size.height / 2.0)))
            contentSize.height += gift.size.height + 16.0
            
            let text = text.update(
                component: MultilineTextComponent(
                    text: .plain(
                        NSAttributedString(
                            string: "This Swiftgram gift crafting flow is temporarily disabled in the merged build while the underlying APIs are being adapted.",
                            font: Font.regular(15.0),
                            textColor: theme.actionSheet.secondaryTextColor,
                            paragraphAlignment: .center
                        )
                    ),
                    maximumNumberOfLines: 0
                ),
                availableSize: CGSize(width: context.availableSize.width - 48.0, height: context.availableSize.height),
                transition: context.transition
            )
            context.add(text.position(CGPoint(x: context.availableSize.width / 2.0, y: contentSize.height + text.size.height / 2.0)))
            contentSize.height += text.size.height + 24.0
            
            let button = button.update(
                component: ButtonComponent(
                    background: ButtonComponent.Background(
                        style: .glass,
                        color: theme.list.itemCheckColors.fillColor,
                        foreground: theme.list.itemCheckColors.foregroundColor,
                        pressedColor: theme.list.itemCheckColors.fillColor.withMultipliedAlpha(0.9)
                    ),
                    content: AnyComponentWithIdentity(
                        id: "ok",
                        component: AnyComponent(
                            MultilineTextComponent(
                                text: .plain(
                                    NSAttributedString(
                                        string: environment.strings.Common_OK,
                                        font: Font.semibold(17.0),
                                        textColor: theme.list.itemCheckColors.foregroundColor,
                                        paragraphAlignment: .center
                                    )
                                )
                            )
                        )
                    ),
                    action: {
                        component.dismiss()
                    }
                ),
                availableSize: CGSize(width: context.availableSize.width - 60.0, height: 52.0),
                transition: context.transition
            )
            context.add(button.position(CGPoint(x: context.availableSize.width / 2.0, y: contentSize.height + button.size.height / 2.0)).cornerRadius(10.0))
            contentSize.height += button.size.height + 16.0 + environment.safeInsets.bottom
            
            return contentSize
        }
    }
}

private final class GiftCraftScreenComponent: Component {
    typealias EnvironmentType = ViewControllerComponentContainer.Environment
    
    let context: AccountContext
    let gift: StarGift.UniqueGift
    
    init(context: AccountContext, gift: StarGift.UniqueGift) {
        self.context = context
        self.gift = gift
    }
    
    static func ==(lhs: GiftCraftScreenComponent, rhs: GiftCraftScreenComponent) -> Bool {
        if lhs.context !== rhs.context {
            return false
        }
        if lhs.gift != rhs.gift {
            return false
        }
        return true
    }
    
    final class View: UIView {
        private let sheet = ComponentView<(ViewControllerComponentContainer.Environment, SheetComponentEnvironment)>()
        private let sheetAnimateOut = ActionSlot<Action<Void>>()
        
        private var component: GiftCraftScreenComponent?
        private var environment: EnvironmentType?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func update(
            component: GiftCraftScreenComponent,
            availableSize: CGSize,
            state: EmptyComponentState,
            environment: Environment<ViewControllerComponentContainer.Environment>,
            transition: ComponentTransition
        ) -> CGSize {
            self.component = component
            
            let environment = environment[ViewControllerComponentContainer.Environment.self].value
            self.environment = environment
            
            let sheetEnvironment = SheetComponentEnvironment(
                isDisplaying: environment.isVisible,
                isCentered: environment.metrics.widthClass == .regular,
                hasInputHeight: !environment.inputHeight.isZero,
                regularMetricsSize: CGSize(width: 430.0, height: 900.0),
                dismiss: { [weak self] _ in
                    guard let self, let environment = self.environment else {
                        return
                    }
                    self.sheetAnimateOut.invoke(Action { _ in
                        environment.controller()?.dismiss(completion: nil)
                    })
                }
            )
            let _ = self.sheet.update(
                transition: transition,
                component: AnyComponent(
                    SheetComponent(
                        content: AnyComponent(
                            GiftCraftSheetContent(
                                context: component.context,
                                gift: component.gift,
                                dismiss: { [weak self] in
                                    guard let self, let environment = self.environment else {
                                        return
                                    }
                                    self.sheetAnimateOut.invoke(Action { _ in
                                        environment.controller()?.dismiss(completion: nil)
                                    })
                                }
                            )
                        ),
                        backgroundColor: .color(environment.theme.actionSheet.opaqueItemBackgroundColor),
                        animateOut: self.sheetAnimateOut
                    )
                ),
                environment: {
                    environment
                    sheetEnvironment
                },
                containerSize: availableSize
            )
            if let sheetView = self.sheet.view {
                if sheetView.superview == nil {
                    self.addSubview(sheetView)
                }
                transition.setFrame(view: sheetView, frame: CGRect(origin: CGPoint(), size: availableSize))
            }
            
            return availableSize
        }
    }
    
    func makeView() -> View {
        return View(frame: CGRect())
    }
    
    func update(
        view: View,
        availableSize: CGSize,
        state: EmptyComponentState,
        environment: Environment<ViewControllerComponentContainer.Environment>,
        transition: ComponentTransition
    ) -> CGSize {
        return view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}

public final class GiftCraftScreen: ViewControllerComponentContainer {
    fileprivate weak var profileGiftsContext: ProfileGiftsContext?
    
    public init(
        context: AccountContext,
        gift: StarGift.UniqueGift,
        profileGiftsContext: ProfileGiftsContext?
    ) {
        self.profileGiftsContext = profileGiftsContext
        
        super.init(
            context: context,
            component: GiftCraftScreenComponent(context: context, gift: gift),
            navigationBarAppearance: .none,
            statusBarStyle: .ignore,
            presentationMode: .modal,
            theme: .default
        )
        
        self.navigationPresentation = .flatModal
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func dismissAnimated() {
        if let view = self.node.hostView.findTaggedView(tag: SheetComponent<ViewControllerComponentContainer.Environment>.View.Tag()) as? SheetComponent<ViewControllerComponentContainer.Environment>.View {
            view.dismissAnimated()
        } else {
            self.dismiss(completion: nil)
        }
    }
}
