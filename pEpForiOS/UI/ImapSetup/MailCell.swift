//
//  MyTableViewMailCustomCell.swift
//  pEpDemo
//
//  Created by ana on 12/4/16.
//  Copyright © 2016 pEp. All rights reserved.
//

import UIKit

class MailCell: UITableViewCell {

    @IBOutlet weak var senderName: UITextView!
    @IBOutlet weak var subject: UITextView!
    @IBOutlet weak var contentMail: UITextView!
    @IBOutlet weak var hour: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    @IBOutlet weak var MailContent: UITextView!

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.selectionStyle = UITableViewCellSelectionStyle.none
    }
}
