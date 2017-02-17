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
    @IBOutlet weak var handShakeButton: UIButton!

    var session: PEPSession?
    
    func updateCell(_ allRecipients:[Identity], indexPath: IndexPath) {
        let identity = allRecipients[indexPath.row]
        if identity.canResetTrust(session: session) {
            handShakeButton.setTitle(
                NSLocalizedString("Reset", comment: "Reset trust"), for: .normal)
        }
        handShakeButton.tag = indexPath.row

        if let un = identity.userName {
            nameLabel.text = un
            emailLabel.text = identity.address
        } else {
            nameLabel.text = identity.address
            emailLabel.text = ""
        }
        setButtonColor(identity: identity)
    }
    
    func setButtonColor(identity: Identity) {
        identity.decorateButton(button: handShakeButton)
    }    
}
