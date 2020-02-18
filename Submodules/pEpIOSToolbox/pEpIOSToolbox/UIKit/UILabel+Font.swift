//
//  UILabel+Font.swift
//  pEpIOSToolbox
//
//  Created by Adam Kowalski on 13/02/2020.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import UIKit

extension UILabel {
    /// Sets pEp default custom font with respecting TextStyle - Dynamic Fonts
    public func pEpSetFontFace() {
        font = UIFont.pEpPreferredFontTypeFace(systemDynamicFont: font)
    }
}
