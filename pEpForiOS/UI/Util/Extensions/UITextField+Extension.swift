//
//  UITextField+Extension.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 25/04/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

extension UITextField {
    public func convertToLoginField(placeholder: String, delegate: UITextFieldDelegate) {
        // common properties
        self.delegate = delegate
        self.placeholder = placeholder

        // properties divided between enabled/disabled
        if isEnabled {
            enableLoginField()
        } else {
            disableLoginField()
        }
    }

    public func disableLoginField() {
        enableOrDisableLoginField(enable: false)
    }

    public func enableLoginField() {
        enableOrDisableLoginField(enable: true)
    }

    public func enableOrDisableLoginField(enable: Bool) {
        let theColor = enable ? UIColor.white : UIColor.gray
        self.textColor = theColor
        if let ph = placeholder {
            self.attributedPlaceholder = NSAttributedString(
                string: ph, attributes: [NSAttributedString.Key.foregroundColor: theColor])
        }
    }
}
