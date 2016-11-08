//
//  RecipientCell.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 07/07/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

open class RecipientCell: UITableViewCell {
    @IBOutlet weak var recipientTextView: UITextView!

    var minimumCaretLocation: Int?
    var titleText: String?
    var message: CdMessage!

    override open func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = UITableViewCellSelectionStyle.none
    }
    
    var recipientType: RecipientType? = nil {
        didSet {
            if let rt = recipientType {
                switch rt {
                case .to:
                    titleText = NSLocalizedString("To: ", comment: "ComposeView")
                    minimumCaretLocation = (titleText! as NSString).length
                    recipientTextView.text = titleText
                case .cc:
                    titleText = NSLocalizedString("CC: ", comment: "ComposeView")
                    minimumCaretLocation = (titleText! as NSString).length
                    recipientTextView.text = titleText
                case .bcc:
                    titleText = NSLocalizedString("BCC: ", comment: "ComposeView")
                    minimumCaretLocation = (titleText! as NSString).length
                    recipientTextView.text = titleText
                }
            }
        }
    }
}
