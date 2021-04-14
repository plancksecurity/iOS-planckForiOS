//
//  String+NSAttributedString.swift
//  pEp
//
//  Created by Adam Kowalski on 27/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

import pEpIOSToolbox

extension String {

    /// Create NSAttributedString
    func attributedString() -> NSAttributedString {
        return NSAttributedString.normalAttributedString(from: self)
    }
}
