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
        setupResetButton()
    }

    @IBAction private func resetButtonPressed() {
        delegate?.resetButtonPressed(on: self)
    }
}

extension TrustManagementResetTableViewCell {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let thePreviousTraitCollection = previousTraitCollection else {
            // Valid case: optional value from Apple.
            return
        }
        if thePreviousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) {
            setupResetButton()
            layoutIfNeeded()
        }
    }

    private func setupResetButton() {
        resetButton.pEpIfyForTrust(backgroundColor: .systemGray2, textColor: .label)
        resetLabel.text = NSLocalizedString("Reset all p≡p data for this comunication partner:",
                                            comment: "Reset all p≡p data for this comunication partner:")
    }
}
