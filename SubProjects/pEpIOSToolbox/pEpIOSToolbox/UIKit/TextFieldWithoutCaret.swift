//
//  TextFieldWithoutCaret.swift
//  pEpIOSToolbox
//
//  Created by Martín Brude on 03/11/2020.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import Foundation
import UIKit

/// Non editable texfield without caret
class TextFieldWithoutCaret: NonEditMenuUITextField {

    override func caretRect(for position: UITextPosition) -> CGRect {
        return .zero
    }
}
