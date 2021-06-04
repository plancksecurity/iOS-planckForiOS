//
//  AlertTextView.swift
//  pEp
//
//  Created by Martín Brude on 24/12/20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

@IBDesignable
public class AlertTextView: UITextView {

    @IBInspectable var placeholderText: String = "" {
        didSet {
            text = placeholderText
        }
    }

    @IBInspectable var isPlaceholder: Bool = true {
        didSet {
            if #available(iOS 13.0, *) {
                textColor = isPlaceholder ? UIColor.pEpGreyButtonLines: .label
            } else {
                textColor = isPlaceholder ? UIColor.pEpGreyButtonLines: .black
            }
        }
    }

    @IBInspectable var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.cgColor
        }
    }

    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }

    func beginEditing() {
        if text == placeholderText {
            isPlaceholder.toggle()
            text = ""
        }
    }

    func endEditing() {
        if text == "" {
            text = placeholderText
            isPlaceholder.toggle()
        }
    }

    func didChange() {
        if text == "" {
            text = placeholderText
            isPlaceholder = true
            selectedTextRange = textRange(from: beginningOfDocument, to: beginningOfDocument)
        } else if isPlaceholder {
            text = text.removeFirst(pattern: placeholderText)
            isPlaceholder = false
        }
    }
}
