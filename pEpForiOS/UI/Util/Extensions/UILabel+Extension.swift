//
//  UILabel+Extension.swift
//  pEp
//
//  Created by Martín Brude on 28/12/20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

extension UILabel {

    /// Sets the system font used in p≡p configured with the text style and the weight,
    /// scaled for accessibility if needed at max 30 point size.
    /// Also enables adjustsFontForContentSizeCategory.
    ///
    /// - Parameters:
    ///   - style: The preferred font style.
    ///   - weight: The preferred font weight.
    public func setPEPFont(style: UIFont.TextStyle, weight: UIFont.Weight) {
        font = UIFont.pepFont(style: style, weight: weight)
        adjustsFontForContentSizeCategory = true
    }
}
