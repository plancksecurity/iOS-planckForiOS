//
//  HandshakeButtonTableViewCell.swift
//  pEpForiOS
//
//  Created by ana on 1/8/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class HandshakeButtonTableViewCell: UITableViewCell {


    @IBOutlet weak var confirmUIButton: UIButton!
    @IBOutlet weak var deniedUIButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = UITableViewCellSelectionStyle.none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
