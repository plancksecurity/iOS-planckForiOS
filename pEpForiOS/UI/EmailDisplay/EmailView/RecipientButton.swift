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
        let recipientButton = RecipientButton(type: .custom)
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
        titleLabel?.adjustsFontSizeToFitWidth = true
        contentHorizontalAlignment = .left
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        /// Get rid of paddings
        contentEdgeInsets = UIEdgeInsets(top: .leastNormalMagnitude,
                                         left: .leastNormalMagnitude,
                                         bottom: .leastNormalMagnitude,
                                         right: .leastNormalMagnitude)

        if let color = color {
            setTitleColor(color, for: .normal)
        } else if #available(iOS 13.0, *) {
            setTitleColor(.secondaryLabel, for: .normal)
            setTitleColor(.tertiaryLabel, for: .highlighted)
            setTitleColor(.tertiaryLabel, for: .selected)
        } else {
            setTitleColor(.lightGray, for: .normal)
            setTitleColor(.darkGray, for: .highlighted)
            setTitleColor(.darkGray, for: .selected)
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
