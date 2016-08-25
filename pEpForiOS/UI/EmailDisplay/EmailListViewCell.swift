//
//  EmailListViewCell.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 16/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

class EmailListViewCell: UITableViewCell {

    @IBOutlet weak var senderLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var isImportantImage: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = UITableViewCellSelectionStyle.None
        isImportantImage.hidden = true
        isImportantImage.layer.cornerRadius = isImportantImage.frame.size.width / 2
        isImportantImage.clipsToBounds = true
        isImportantImage.layer.borderWidth = 2
        isImportantImage.layer.borderColor = UIColor(red:255/255.0, green:165/255.0, blue:0/255.0, alpha: 1.0).CGColor

    }

}