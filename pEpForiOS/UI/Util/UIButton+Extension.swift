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
        titleLabel?.numberOfLines = 0
        titleLabel?.lineBreakMode = .byWordWrapping
        titleLabel?.textAlignment = .center

        self.backgroundColor = backgroundColor
        setTitleColor(textColor, for: .normal)
        layer.cornerRadius = 2
        let insetV: CGFloat = 15
        let insetH: CGFloat = 15
        contentEdgeInsets = UIEdgeInsetsMake(insetV, insetH, insetV, insetH)
    }

    func convertToLoginButton(placeholder: String) {
        self.backgroundColor = UIColor.clear
        self.tintColor = UIColor.pEpGreen
        self.layer.borderColor = UIColor.pEpGreen.cgColor
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

public class handshakeButton: UIButton {

    public override var intrinsicContentSize: CGSize {
        if let titleContentSize = self.titleLabel?.intrinsicContentSize {
            if titleContentSize.height <= 25.0 {
                return CGSize(width: titleContentSize.width, height: 40.0)
            } else {
                return titleContentSize
            }
        } else {
            return super.intrinsicContentSize
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if let titleWidth = self.titleLabel?.frame.size.width {
            self.titleLabel?.preferredMaxLayoutWidth = titleWidth + 10.0
            super.layoutSubviews()
        }
    }

}
