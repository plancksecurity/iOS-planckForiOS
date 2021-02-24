//
//  TextFieldWithoutSelection.swift
//  pEp
//
//  Created by Martín Brude on 12/1/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

/// UITextView property 'isSelectable', when it's false, doesn't allow the user to tap links.
/// This allows the interaction with the link and disable the selection.
class TextFieldWithoutSelection: UITextView {

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let pos = closestPosition(to: point) else { return false }
        guard let range = tokenizer.rangeEnclosingPosition(pos, with: .character, inDirection: .layout(.left)) else { return false }
        let startIndex = offset(from: beginningOfDocument, to: range.start)
        return attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil
    }
}
