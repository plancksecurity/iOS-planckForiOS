//
//  RecipientCell.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 07/07/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

public class RecipientCell: UITableViewCell {
    @IBOutlet weak var recipientTypeLabel: UILabel!
    @IBOutlet weak var recipientTextField: UITextField!

    var recipientType: RecipientType = .To {
        didSet {
            switch recipientType {
            case .To:
                recipientTypeLabel.text = NSLocalizedString("To:", comment: "ComposeView")
            case .CC:
                recipientTypeLabel.text = NSLocalizedString("CC:", comment: "ComposeView")
            case .BCC:
                recipientTypeLabel.text = NSLocalizedString("BCC:", comment: "ComposeView")
            }
        }
    }

    var message: Message!
}
