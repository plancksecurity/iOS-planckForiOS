//
//  UIButton+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 20.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

extension UIButton {
    /**
     Makes the button the typical look for a pEp button used in the handshake dialogs.
     */
    public func pEpIfyForTrust(backgroundColor: UIColor, textColor: UIColor, insetPlusHorizontal: CGFloat = 20, insetPlusVertical: CGFloat = 10, cornerRadius: CGFloat = 10) {
        titleLabel?.numberOfLines = 0
        titleLabel?.lineBreakMode = .byWordWrapping
        titleLabel?.textAlignment = .center

        self.backgroundColor = backgroundColor
        setTitleColor(textColor, for: .normal)

        layer.cornerRadius = cornerRadius
        clipsToBounds = true

        var insets = contentEdgeInsets
        insets.left = insets.left + insetPlusHorizontal
        insets.right = insets.right + insetPlusHorizontal
        insets.top = insets.top + insetPlusVertical
        insets.bottom = insets.bottom + insetPlusVertical
        contentEdgeInsets = insets
    }

    public func convertToLoginButton(placeholder: String) {
        backgroundColor = UIColor.clear
        tintColor = UIColor.pEpGreen
        setTitle(placeholder, for: .normal)
    }

    static func backButton(with text: String) -> UIButton {
        let image = UIImage(named: "arrow-rgt-active")
        let tintedimage = image?.withRenderingMode(.alwaysTemplate)
        let buttonLeft = UIButton(type: UIButton.ButtonType.custom)
        buttonLeft.setImage(tintedimage, for: .normal)
        buttonLeft.imageView?.contentMode = .scaleToFill
        buttonLeft.imageView?.tintColor = UIColor.pEpGreen
        buttonLeft.setTitle(text, for: .normal)
        buttonLeft.tintColor = UIColor.pEpGreen
        buttonLeft.setTitleColor(UIColor.pEpGreen, for: .normal)
        return buttonLeft
    }

    /// Sets the system font used in p≡p configured with the text style and the weight,
    /// scaled for accessibility if needed at max 30 point size.
    /// Also enables adjustsFontForContentSizeCategory.
    ///
    /// - Parameters:
    ///   - style: The preferred font style.
    ///   - weight: The preferred font weight.
    public func setPEPFont(style: UIFont.TextStyle, weight: UIFont.Weight) {
        titleLabel?.setPEPFont(style: style, weight: weight)
    }
}
