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

    /// Constructor
    ///
    /// Instanciate a recipient button with the text passed by parameter
    /// - Parameter text: The text to display
    /// - Returns: The recipient button configured
    static func with(text: String, action: (() -> Void)? = nil) -> RecipientButton {
        let recipientButton = RecipientButton(type: .system)
        recipientButton.setup(text: text, action: action)
        return recipientButton
    }

    /// Setup the recipient button with the text and colors passed by parameters.
    /// - Parameters:
    ///   - text: The text of the button
    ///   - color: The title color. If nil, default values will be used. 
    public func setup(text: String, color: UIColor? = nil, action: (() -> Void)? = nil) {
        self.callbackAction = action
        addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        isUserInteractionEnabled = true
        setTitle(text, for: .normal)
        titleLabel?.adjustsFontSizeToFitWidth = false
        contentHorizontalAlignment = .left
        titleLabel?.numberOfLines = 1
        titleLabel?.lineBreakMode = .byTruncatingTail
        /// Get rid of paddings
        contentEdgeInsets = UIEdgeInsets(top: .leastNormalMagnitude,
                                         left: .leastNormalMagnitude,
                                         bottom: .leastNormalMagnitude,
                                         right: .leastNormalMagnitude)

        if let color = color {
            setTitleColor(color, for: .normal)
            if #available(iOS 13.0, *) {
                if UITraitCollection.current.userInterfaceStyle == .dark {
                    setTitleColor(UIColor.secondaryLabel, for: .highlighted)
                    setTitleColor(UIColor.secondaryLabel, for: .selected)
                } else {
                    setTitleColor(UIColor.darkGray, for: .highlighted)
                    setTitleColor(UIColor.darkGray, for: .selected)
                }

            } else {
                setTitleColor(UIColor.darkGray, for: .highlighted)
                setTitleColor(UIColor.darkGray, for: .selected)
            }
        } else {
            if #available(iOS 13.0, *) {
                setTitleColor(.secondaryLabel, for: .normal)
                setTitleColor(.label, for: .highlighted)
                setTitleColor(.label, for: .selected)
            } else {
                // iOS 12
                setTitleColor(.black, for: .normal)
                setTitleColor(.darkGray, for: .highlighted)
                setTitleColor(.darkGray, for: .selected)
            }
        }

        titleLabel?.font = UIFont.pepFont(style: .footnote, weight: .semibold)
        titleLabel?.textAlignment = .natural
        sizeToFit()
    }

    @objc private func buttonPressed() {
        if let action = callbackAction {
            action()
        }
    }
}
