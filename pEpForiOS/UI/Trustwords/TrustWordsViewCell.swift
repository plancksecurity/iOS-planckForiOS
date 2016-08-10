//
//  TrustWordsViewCell.swift
//  pEpForiOS
//
//  Created by ana on 11/7/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class TrustWordsViewCell: UITableViewCell {

    @IBOutlet weak var handshakeContactUILabel: UILabel!
    @IBOutlet weak var handshakeUIButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = UITableViewCellSelectionStyle.None
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
