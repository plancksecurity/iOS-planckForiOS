//
//  PerAccountSyncAccountTableViewCell.swift
//  pEp
//
//  Created by Xavier Algarra on 07/01/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

class PerAccountSyncAccountTableViewCell: UITableViewCell {


    @IBOutlet weak var accountTitleLabel: UILabel!
    @IBOutlet weak var perAccountSwitch: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
