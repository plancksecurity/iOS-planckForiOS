//
//  UIImage+DisabledUITextField.swift
//  pEp
//
//  Created by Dirk Zimmermann on 22.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

extension UIImage {
    /**
     An image that can be used for disabling UITextFields.
     */
    open static func disabledBackgroundImageUITextField() -> UIImage? {
        let image = generate(size: CGSize(width: 100, height: 100)) { context, size in
            let fillColor = UIColor.black
            var red, green, blue, alpha: CGFloat
            (red, green, blue, alpha) = (0, 0, 0, 0)
            fillColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            alpha = 1.0
            context.setFillColor(red: red, green: green, blue: blue, alpha: alpha)
            context.setStrokeColor(red: red, green: green, blue: blue, alpha: alpha)
            context.fill(CGRect(origin: CGPoint(x: 0, y: 0), size: size))
        }
        return image
    }
}
