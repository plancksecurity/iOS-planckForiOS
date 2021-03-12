//
//  TextViewContainingTableViewCell.swift
//  pEp
//
//  Created by Andreas Buff on 08.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

//IUOS-1369: Maybe obsolete.
protocol TextViewContainingTableViewCellProtocol {
    var textView: UITextView! { get set }
    func setFocus()
}

class TextViewContainingTableViewCell: UITableViewCell, TextViewContainingTableViewCellProtocol, UITextViewDelegate {
    @IBOutlet weak public var textView: UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
        textView.delegate = self
        textView.adjustsFontForContentSizeCategory = true
    }

    func setFocus() {
        let rangeAtTheEnd = textView.textRange(from: textView.endOfDocument,
                                               to: textView.endOfDocument)
        textView.selectedTextRange = rangeAtTheEnd
        textView.becomeFirstResponder()
    }

    func setup() {
        if #available(iOS 13.0, *) {
            if UITraitCollection.current.userInterfaceStyle == .light {
                backgroundColor = .white
            } else {
                backgroundColor = .secondarySystemBackground
            }
        } else {
            backgroundColor = .white
        }
    }
}
