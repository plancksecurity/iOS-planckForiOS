//
//  PrivacyInfoTableViewCell.swift
//  pEpForiOS
//
//  Created by Igor Vojinovic on 1/20/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

class PrivacyInfoTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "pivacyInfoCell"
    
    @IBOutlet weak var infoTitleLabel: UILabel!
    @IBOutlet weak var infoTextLabel: UILabel!
    
    func showExplanation() {
        infoTitleLabel.text = "Explanation.title".localized
        infoTextLabel.text = "Explanation.text".localized
    }
    
    func showSuggestion() {
        infoTitleLabel.text = "Suggestion.title".localized
        infoTextLabel.text = "Suggestion.text".localized
    }
    
}
