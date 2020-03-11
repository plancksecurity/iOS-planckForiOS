//
//  TrustManagementResetTableViewCell.swift
//  pEp
//
//  Created by Martin Brude on 17/02/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

final class TrustManagementResetTableViewCell: UITableViewCell {

    @IBOutlet weak var partnerNameLabel: UILabel!
    @IBOutlet weak var partnerImageView: UIImageView!
    @IBOutlet weak var resetLabel: UILabel!
    @IBOutlet weak var resetButton: UIButton!
    
    weak var delegate : TrustManagementResetTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        
           //Reset Button
           resetButton.pEpIfyForTrust(backgroundColor: .pEpGrayBackgroundReset, textColor: .white)
        
           //Reset label
           resetLabel.text = NSLocalizedString("Reset all p≡p data for this comunication partner:",
                                               comment: "Reset all p≡p data for this comunication partner:")

    }

    @IBAction private func resetButtonPressed() {
        delegate?.resetButtonPressed(on: self)
    }
}
