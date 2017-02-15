//
//  PrivacyInfoTableViewCell.swift
//  pEpForiOS
//
//  Created by Igor Vojinovic on 1/20/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

class PrivacyInfoTableViewCell: UITableViewCell {
    static let reuseIdentifier = "pivacyInfoCell"
    
    @IBOutlet weak var infoTitleLabel: UILabel!
    @IBOutlet weak var infoTextLabel: UILabel!
    
    func showExplanation(message: Message) {
        infoTitleLabel.text = PEPUtil.pEpTitle(pEpRating: message.pEpRating())
        infoTextLabel.text = PEPUtil.pEpExplanation(pEpRating: message.pEpRating())
    }
    
    func showSuggestion(message: Message) {
        infoTitleLabel.text = "Suggestion".localized
        infoTextLabel.text = PEPUtil.pEpSuggestion(pEpRating: message.pEpRating())
    }
    
}
