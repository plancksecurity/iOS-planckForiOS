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
     A background image that can be used for disabled UITextFields.
     See `UITextField.isEnabled`, `UITextField.disabledBackground`.
     */
    open static func disabledUITextFieldBackgroundImage() -> UIImage? {
        let image = generate(size: CGSize(width: 1, height: 1)) { context, size in
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

    /**
     A background image that can be used for enabled UITextFields.
     See `UITextField.background`.
     */
    open static func defaultUITextFieldBackgroundImage() -> UIImage? {
        let image = generate(size: CGSize(width: 1, height: 1)) { context, size in
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
