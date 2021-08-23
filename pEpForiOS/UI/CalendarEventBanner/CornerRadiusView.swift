//
//  CornerRadiusView.swift
//  pEpForiOS
//
//  Created by Martín Brude on 14/7/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit

@IBDesignable
class CornerRadiusView: UIView {

    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
}
