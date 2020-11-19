//
//  AttachmentView.swift
//  pEp
//
//  Created by Martín Brude on 19/11/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

@IBDesignable
class AttachmentView : UIView {

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
