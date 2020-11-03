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

    /**
     Does the content fit the button bounds?
     */
    public func contentFitsWidth() -> Bool {
        let iSize = intrinsicContentSize
        let actSize = bounds.size
        return iSize.width < actSize.width
    }
    
    static func backButton(with text: String) -> UIButton {
        let img2 = UIImage(named: "arrow-rgt-active")
        let tintedimage = img2?.withRenderingMode(.alwaysTemplate)
        let buttonLeft = UIButton(type: UIButton.ButtonType.custom)
        buttonLeft.setImage(tintedimage, for: .normal)
        buttonLeft.imageView?.contentMode = .scaleToFill
        buttonLeft.imageView?.tintColor = UIColor.pEpGreen
        buttonLeft.setTitle(text, for: .normal)
        buttonLeft.tintColor = UIColor.pEpGreen
        buttonLeft.setTitleColor(UIColor.pEpGreen, for: .normal)
        return buttonLeft
    }
}
