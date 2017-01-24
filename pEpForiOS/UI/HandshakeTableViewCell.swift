//
//  HandshakeTableViewCell.swift
//  pEpForiOS
//
//  Created by Igor Vojinovic on 1/20/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel

class HandshakeTableViewCell: UITableViewCell {

    static let reuseIdentifier = "handshakeCell"
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var handShakeButton: RoundedButton!
    
    func updateCell(_ allRecipients:[Identity], indexPath: IndexPath) {
        let identity = allRecipients[indexPath.row]
        handShakeButton.tag = indexPath.row
        nameLabel.text = identity.userName
        nameLabel.text = identity.address
    }
    
}
