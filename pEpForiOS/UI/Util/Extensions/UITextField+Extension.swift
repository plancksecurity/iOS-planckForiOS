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
    }
}
