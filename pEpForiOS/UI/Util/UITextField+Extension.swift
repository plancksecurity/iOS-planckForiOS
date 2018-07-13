//
//  UITextField+Extension.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 25/04/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

extension UITextField {
    func convertToLoginField(placeholder: String, delegate: UITextFieldDelegate) {
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

    func disableLoginField() {
        enableOrDisableLoginField(enable: false)
    }

    func enableLoginField() {
        enableOrDisableLoginField(enable: true)
    }

    func enableOrDisableLoginField(enable: Bool) {
        let theColor = enable ? UIColor.white : UIColor.gray
        self.textColor = theColor
//        self.layer.borderColor = theColor.cgColor
        if let ph = placeholder {
            self.attributedPlaceholder = NSAttributedString(
                string: ph, attributes: [NSAttributedStringKey.foregroundColor: theColor])
        }
    }
}
