//
//  HandshakePartnerTableViewCell.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 20.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

class HandshakePartnerTableViewCell: UITableViewCell {
    @IBOutlet weak var stopTrustingButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var wrongButton: UIButton!
    @IBOutlet weak var partnerImageView: UIImageView!
    @IBOutlet weak var pEpStatusImageView: UIImageView!
    @IBOutlet weak var partnerNameLabel: UILabel!
    @IBOutlet weak var privacyStatusTitle: UILabel!
    @IBOutlet weak var privacyStatusDescription: UILabel!
    @IBOutlet weak var trustWordsLabel: UILabel!

    override func awakeFromNib() {
        stopTrustingButton.pEpIfyForTrust(backgroundColor: UIColor.pEpYellow, textColor: .black)
        confirmButton.pEpIfyForTrust(backgroundColor: UIColor.pEpGreen, textColor: .white)
        wrongButton.pEpIfyForTrust(backgroundColor: UIColor.pEpRed, textColor: .white)
        setNeedsLayout()
    }

    func updateCell(indexPath: IndexPath, message: Message, partner: Identity,
                    session: PEPSession?, imageProvider: IdentityImageProvider) {
        partnerNameLabel.text = partner.userName ?? partner.address

        let theSession = session ?? PEPSession()
        let rating = partner.pEpRating(session: theSession)
        pEpStatusImageView.image = rating.statusIcon()

        imageProvider.image(forIdentity: partner) { [weak self] img, ident in
            GCD.onMain() {
                if partner == ident {
                    self?.partnerImageView.image = img
                }
            }
        }
    }
}
