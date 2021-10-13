//
//  CornerRadiusView.swift
//  pEpForiOS
//
//  Created by Martín Brude on 14/7/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit

// This UIView facilitates to define the corner radius of through storyboard.
// To use it just drag and drop a UIView, change the class to use this one, and setup cornerRadius in the attribute inspector.
@IBDesignable
class CornerRadiusView: UIView {

    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
}
