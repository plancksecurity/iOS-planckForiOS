//
//  RecipientButton.swift
//  pEp
//
//  Created by Martín Brude on 14/4/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation

class RecipientButton: UIButton {

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
    static func with(text: String) -> RecipientButton {
        let recipientButton = RecipientButton(type: .custom)
        recipientButton.isUserInteractionEnabled = true
        recipientButton.setTitle(text, for: .normal)
        recipientButton.titleLabel?.adjustsFontSizeToFitWidth = true
        recipientButton.contentHorizontalAlignment = .left
        recipientButton.setContentHuggingPriority(.required, for: .horizontal)
        recipientButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        /// Get rid of paddings
        recipientButton.contentEdgeInsets = UIEdgeInsets(top: .leastNormalMagnitude,
                                                         left: .leastNormalMagnitude,
                                                         bottom: .leastNormalMagnitude,
                                                         right: .leastNormalMagnitude)

        if #available(iOS 13.0, *) {
            recipientButton.setTitleColor(.secondaryLabel, for: .normal)
            recipientButton.setTitleColor(.tertiaryLabel, for: .highlighted)
            recipientButton.setTitleColor(.tertiaryLabel, for: .selected)
        } else {
            recipientButton.setTitleColor(.lightGray, for: .normal)
            recipientButton.setTitleColor(.darkGray, for: .highlighted)
            recipientButton.setTitleColor(.darkGray, for: .selected)
        }
        recipientButton.titleLabel?.font = UIFont.pepFont(style: .footnote, weight: .semibold)
        recipientButton.titleLabel?.textAlignment = .natural
        recipientButton.sizeToFit()

        return recipientButton
    }
}
