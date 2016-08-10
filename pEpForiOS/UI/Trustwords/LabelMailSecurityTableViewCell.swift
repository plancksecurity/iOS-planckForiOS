//
//  LabelMailSecurityTableViewCell.swift
//  pEpForiOS
//
//  Created by ana on 12/7/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class LabelMailSecurityTableViewCell: UITableViewCell {

    @IBOutlet weak var mailSecurityUILabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = UITableViewCellSelectionStyle.None
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
