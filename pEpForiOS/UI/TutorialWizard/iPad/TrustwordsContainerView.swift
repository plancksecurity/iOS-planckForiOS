//
//  TrustwordsContainer.swift
//  pEp
//
//  Created by Martín Brude on 24/2/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit

@IBDesignable
class TrustwordsContainerView: UIView {

    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.cgColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
}
