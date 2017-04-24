//
//  UITextField+Extension.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 25/04/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

extension UITextField {
    func convertToLoginTextField(placeHolder: String) {
        self.backgroundColor = UIColor.clear
        self.tintColor = UIColor.white
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 1.0
        self.attributedPlaceholder = NSAttributedString(string:placeHolder, attributes: [NSForegroundColorAttributeName: UIColor.white])
    }
}
