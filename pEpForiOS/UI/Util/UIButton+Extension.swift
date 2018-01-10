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
    func pEpIfyForTrust(backgroundColor: UIColor, textColor: UIColor) {
        self.backgroundColor = backgroundColor
        setTitleColor(textColor, for: .normal)
        layer.cornerRadius = 2
        let insetV: CGFloat = 5
        let insetH: CGFloat = 5
        contentEdgeInsets = UIEdgeInsetsMake(insetV, insetH, insetV, insetH)
    }

    func convertToLoginButton(placeholder: String) {
        self.backgroundColor = UIColor.clear
        self.tintColor = UIColor.white
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 1.0
        self.setTitle(placeholder, for: .normal)
    }

    /**
     Does the content fit the button bounds?
     */
    func contentFitsWidth() -> Bool {
        let iSize = intrinsicContentSize
        let actSize = bounds.size
        return iSize.width < actSize.width
    }
}
