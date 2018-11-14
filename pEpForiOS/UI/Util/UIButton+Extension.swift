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

public class HandshakeButton: UIButton {

    public func roundCorners(corners: UIRectCorner, radius: CGFloat){
        clipsToBounds = true
        layer.cornerRadius = 0
        let maskPath = UIBezierPath(roundedRect: bounds,
                                    byRoundingCorners: corners,
                                    cornerRadii: CGSize(width: radius, height: radius))
        let maskLayer = CAShapeLayer()
        maskLayer.bounds = frame
        maskLayer.position = center
        maskLayer.path = maskPath.cgPath

        layer.mask = maskLayer
    }
}
