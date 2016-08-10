//
//  HandshakeLabelTableViewCell.swift
//  pEpForiOS
//
//  Created by ana on 29/7/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class HandshakeLabelTableViewCell: UITableViewCell {

    @IBOutlet weak var handshakeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = UITableViewCellSelectionStyle.None
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
