//
//  RecipientButton.swift
//  pEp
//
//  Created by Martín Brude on 14/4/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation

class RecipientButton: UIButton {

    private var callbackAction: (() -> Void)? = nil
    override var intrinsicContentSize: CGSize {
        return titleLabel?.intrinsicContentSize ?? .zero
    }
}

extension RecipientButton {

    //TODO: remove this ´with´ method.

    /// Constructor
    ///
    /// Instanciate a recipient button with the text passed by parameter
    /// - Parameter text: The text to display
    /// - Returns: The recipient button configured
    static func with(text: String, action: (() -> Void)? = nil) -> RecipientButton {
        let recipientButton = RecipientButton(type: .system)
        recipientButton.setup(text: text, color: .yellow, action: action)
        return recipientButton
    }

    /// Setup the recipient button with the text and colors passed by parameters.
    /// - Parameters:
    ///   - text: The text of the button
    ///   - color: The title color. If nil, default values will be used. 
    public func setup(text: String, color: UIColor? = nil, action: (() -> Void)? = nil) {
        self.callbackAction = action
        isUserInteractionEnabled = action != nil
        contentHorizontalAlignment = .left
        addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        setTitle(text, for: .normal)

        /// Get rid of paddings
        contentEdgeInsets = UIEdgeInsets(top: .leastNormalMagnitude,
                                         left: .leastNormalMagnitude,
                                         bottom: .leastNormalMagnitude,
                                         right: .leastNormalMagnitude)
        titleLabel?.font = UIFont.pepFont(style: .footnote, weight: .semibold)
        titleLabel?.textAlignment = .natural
        if let titleColor = color {
            setTitleColor(titleColor)
        }
        sizeToFit()
    }

    private func setTitleColor(_ color: UIColor) {
        setTitleColor(color, for: .normal)
        if #available(iOS 13.0, *) {
            if UITraitCollection.current.userInterfaceStyle == .dark {
                setTitleColor(UIColor.secondaryLabel, for: [.highlighted, .selected])
            } else {
                setTitleColor(UIColor.darkGray, for: [.highlighted, .selected])
            }
        } else {
            setTitleColor(UIColor.darkGray, for: [.highlighted, .selected])
        }
    }

    @objc private func buttonPressed() {
        if let action = callbackAction {
            action()
        }
    }

}
