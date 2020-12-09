//
//  ConfigurableCaretTextField.swift
//  pEpIOSToolbox
//
//  Created by Martín Brude on 03/11/2020.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import Foundation
import UIKit

/// Non editable texfield without caret
public class ConfigurableCaretTextField: NonEditMenuUITextField {

    public var shouldShowCaret: Bool = true

    public override func caretRect(for position: UITextPosition) -> CGRect {
        if shouldShowCaret {
            return super.caretRect(for: position)
        }
        return .zero
    }
}
