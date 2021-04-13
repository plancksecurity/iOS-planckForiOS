//
//  HandshakePartnerTableViewCell.swift
//  pEp
//
//  Created by Martin Brude on 07/02/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

/// UITableViewCell for trust management screen
final class TrustManagementTableViewCell: UITableViewCell {
 
    //Content
    @IBOutlet weak var partnerImageView: UIImageView!
    @IBOutlet weak var privacyStatusImageView: UIImageView!
    @IBOutlet weak var partnerNameLabel: UILabel!
    @IBOutlet weak var privacyStatusLabel: UILabel!
    @IBOutlet weak var trustwordsLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var languageButton: UIButton!
    
    //Only for i18n and layout
    @IBOutlet weak var resetLabel: UILabel!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    
    //Hide these views in case pepColor is not yellow.
    @IBOutlet weak var trustwordsStackView: UIStackView!
    @IBOutlet weak var trustwordsButtonsContainer: UIView!
    
    weak var delegate : TrustManagementTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    /// Reset attributes of the cell that are not related to content.
    override func prepareForReuse() {
        super.prepareForReuse()
        removeGestureRecognizers()
    }

    // MARK: - Actions
    
    @IBAction private func languageButtonPressed() {
        delegate?.languageButtonPressed(on: self)
    }
    
    @IBAction private func declineButtonPressed() {
        delegate?.declineButtonPressed(on: self)
    }

    @IBAction private func confirmButtonPressed() {
        delegate?.confirmButtonPressed(on: self)
    }

    @IBAction private func resetButtonPressed() {
        delegate?.resetButtonPressed(on: self)
    }
    
    @objc private func trustwordsLabelPressed() {
        delegate?.trustwordsLabelPressed(on: self)
    }
    
    // MARK: - Private
    
    private func setupButtons() {
        //Buttons
        if #available(iOS 13.0, *), UITraitCollection.current.userInterfaceStyle == .dark {
            resetButton.pEpIfyForTrust(backgroundColor: .systemGray2, textColor: .label)
            confirmButton.pEpIfyForTrust(backgroundColor: .pEpGreen, textColor: .label)
            declineButton.pEpIfyForTrust(backgroundColor: .pEpRed, textColor: .label)
        } else {
            resetButton.pEpIfyForTrust(backgroundColor: .pEpGrayBackgroundReset, textColor: .white)
            confirmButton.pEpIfyForTrust(backgroundColor: .pEpGreen, textColor: .white)
            declineButton.pEpIfyForTrust(backgroundColor: .pEpRed, textColor: .white)
        }
    }

    /// Setup the view with the row data.
    private func setupView() {
        removeGestureRecognizers()

        let gesture = UITapGestureRecognizer(target: self, action: #selector(trustwordsLabelPressed))
        trustwordsLabel.addGestureRecognizer(gesture)

        //Confirm Button
        let confirmTitle = NSLocalizedString("Confirm", comment: "Confirm correct trustwords/PGP fingerprint")
        confirmButton.setTitle(confirmTitle, for: .normal)

        //Decline Button
        let declineTitle = NSLocalizedString("Decline", comment: "Incorrect trustwords/PGP fingerprint")
        declineButton.setTitle(declineTitle, for: .normal)

        setupButtons()

        //Reset label
        resetLabel.text = NSLocalizedString("Reset all p≡p data for this comunication partner:",
                                            comment: "Reset all p≡p data for this comunication partner:")
        //Image view
        partnerImageView.layer.cornerRadius = 10
        partnerImageView.layer.masksToBounds = true
    }

    private func removeGestureRecognizers() {
        let existingGRs = gestureRecognizers ?? []
        for gr in existingGRs {
            removeGestureRecognizer(gr)
        }
    }
}
