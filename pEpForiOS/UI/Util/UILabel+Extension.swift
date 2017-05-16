//
//  UILabel+Extension.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 16/05/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

extension UILabel {
    func convertToLoginErrorLabel(placeHolder: String) {
        self.backgroundColor = UIColor.clear
        self.tintColor = UIColor.white
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 1.0
        self.textColor = UIColor.red
    }
}
