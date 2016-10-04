//
//  LabelMailExplantionSecurityTableViewCell.swift
//  pEpForiOS
//
//  Created by ana on 14/7/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class LabelMailExplantionSecurityTableViewCell: UITableViewCell {
    @IBOutlet weak var mailExplanationSecurityUILabel: UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = UITableViewCellSelectionStyle.none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
