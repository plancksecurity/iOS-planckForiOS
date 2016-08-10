//
//  RecipientCell.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 07/07/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

public class RecipientCell: UITableViewCell {
    @IBOutlet weak var recipientTextView: UITextView!

    var minimumCaretLocation: Int?
    var titleText: String?
    var message: Message!

    override public func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = UITableViewCellSelectionStyle.None
    }
    
    var recipientType: RecipientType? = nil {
        didSet {
            if let rt = recipientType {
                switch rt {
                case .To:
                    titleText = NSLocalizedString("To: ", comment: "ComposeView")
                    minimumCaretLocation = (titleText! as NSString).length
                    recipientTextView.text = titleText
                case .CC:
                    titleText = NSLocalizedString("CC: ", comment: "ComposeView")
                    minimumCaretLocation = (titleText! as NSString).length
                    recipientTextView.text = titleText
                case .BCC:
                    titleText = NSLocalizedString("BCC: ", comment: "ComposeView")
                    minimumCaretLocation = (titleText! as NSString).length
                    recipientTextView.text = titleText
                }
            }
        }
    }
}