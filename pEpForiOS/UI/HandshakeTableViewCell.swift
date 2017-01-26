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
        nameLabel.text = identity.displayString
        nameLabel.text = identity.address
        setButtonColor(identity: identity)
    }
    
    func setButtonColor(identity: Identity) {
        switch identity.pEpColor() {
        case PEP_color_no_color:
            print("NO COLOR")
            handShakeButton.borderColor = .pEpRed
            handShakeButton.backgroundColor = .pEpRed
            handShakeButton.borderHighlightedColor = .pEpRed
            break
        case PEP_color_red:
            print("RED COLOR")
            handShakeButton.borderColor = .pEpRed
            handShakeButton.backgroundColor = .pEpRed
            handShakeButton.borderHighlightedColor = .pEpRed
            break
        case PEP_color_green:
            print("GREEN COLOR")
            handShakeButton.borderColor = .pEpGreen
            handShakeButton.backgroundColor = .pEpGreen
            handShakeButton.borderHighlightedColor = .pEpGreen
            break
        case PEP_color_yellow:
            print("YELLOW COLOR")
            handShakeButton.borderColor = .pEpYellow
            handShakeButton.backgroundColor = .pEpYellow
            handShakeButton.borderHighlightedColor = .pEpYellow
            break
        default:
            break
        }
    }
    
}
