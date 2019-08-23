//
//  String+pEp.swift
//  pEpIOSToolbox
//
//  Created by Alejandro Gelos on 09/08/2019.
//  Copyright © 2019 pEp Security SA. All rights reserved.
//

import UIKit

extension String {
    public func paintPEPToPEPColour() -> NSAttributedString {
        let range = (self as NSString).range(of: "p≡p")
        let paintedText = NSMutableAttributedString(string: self)

        paintedText.addAttribute(
            NSAttributedString.Key.foregroundColor, value: UIColor.pEpGreen, range: range)
        return paintedText
    }
}
