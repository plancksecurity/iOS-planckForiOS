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
public class ConfigurableCaretTextField: UITextField {

    public var shouldShowCaret: Bool = true
    public var shouldSelect: Bool = true

    public override func caretRect(for position: UITextPosition) -> CGRect {
        if shouldShowCaret {
            return super.caretRect(for: position)
        }
        return .zero
    }

    public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if shouldSelect {
            return super.canPerformAction(action, withSender: sender)
        }
        return false
    }

    public override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        if shouldSelect {
            return super.selectionRects(for: range)
        }
        return []
    }
}
