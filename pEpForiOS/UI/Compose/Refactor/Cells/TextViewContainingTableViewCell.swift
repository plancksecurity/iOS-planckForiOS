//
//  TextViewContainingTableViewCell.swift
//  pEp
//
//  Created by Andreas Buff on 08.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

//IOS-1369: move
protocol TextViewManagingViewModelProtocol {
    func handleTextDidChange(textView: NSAttributedString)
    func textViewContainingTableViewCell(_ cell: TextViewContainingTableViewCell,
                                         textViewDidBeginEditing textView: UITextView)
    func textViewContainingTableViewCell(_ cell: TextViewContainingTableViewCell,
                                         textViewDidChangeSelection textView: UITextView)
    func textViewContainingTableViewCell(_ cell: TextViewContainingTableViewCell,
                                         textViewDidEndEditing textView: UITextView)
}

protocol TextViewContainingTableViewCellProtocol {
    var textView: UITextView! { get set }
}

class TextViewContainingTableViewCell: UITableViewCell, TextViewContainingTableViewCellProtocol {

    @IBOutlet weak public var textView: UITextView!
}
