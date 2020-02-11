//
//  HandshakePartnerTableViewCellV2.swift
//  pEp
//
//  Created by Martin Brude on 07/02/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

/// Delegate to notify the events in the cell.
protocol HandshakeTableViewCellDelegate: class {
    
    /// Delegate method to notify the language button has been pressed.
    /// - Parameter cell: The cell where the language button has been pressed
    func languageButtonPressed(on cell: HandshakeTableViewCell)
    /// Delegate method to notify the decline button has been pressed.
    /// - Parameter cell: The cell where the decline button has been pressed
    func declineButtonPressed(on cell: HandshakeTableViewCell)
    /// Delegate method to notify the confirm button has been pressed.
    /// - Parameter cell: The cell where the confirm button has been pressed
    func confirmButtonPressed(on cell: HandshakeTableViewCell)
    /// Delegate method to notify the reset button has been pressed.
    /// - Parameter cell: The cell where the reset button has been pressed
    func resetButtonPressed(on cell: HandshakeTableViewCell)
    /// Delegate method to notify the trustwords label has been pressed.
    /// - Parameter cell: The cell where the trustwords label has been pressed
    func trustwordsLabelPressed(on cell : HandshakeTableViewCell)
}

/// UITableViewCell for handshake screen
final class HandshakeTableViewCell: UITableViewCell {

    //Content
    @IBOutlet weak var partnerImageView: UIImageView!
    @IBOutlet weak var privacyStatusImageView: UIImageView!
    @IBOutlet weak var partnerNameLabel: UILabel!
    @IBOutlet weak var privacyStatusLabel: UILabel!
    @IBOutlet weak var trustwordsLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var languageButton: UIButton!
    
    //Only for i18n and layout
    @IBOutlet private weak var resetLabel: UILabel!
    @IBOutlet private weak var declineButton: UIButton!
    @IBOutlet private weak var confirmButton: UIButton!
    @IBOutlet private weak var resetButton: UIButton!
    
    //Hide these views in case pepColor is not yellow.
    @IBOutlet weak var trustwordsStackView: UIStackView!
    @IBOutlet weak var trustwordsButtonsContainer: UIView!
    weak var delegate : HandshakeTableViewCellDelegate?
    @IBOutlet weak var rightSideStackView: UIStackView!
    
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
    
    /// Setup the view with the row data.
    private func setupView() {
        removeGestureRecognizers()

        let gesture = UITapGestureRecognizer(target: self, action: #selector(trustwordsLabelPressed))
        trustwordsLabel.addGestureRecognizer(gesture)
    
        //Confirm Button
        let confirmTitle = NSLocalizedString("Confirm", comment: "Confirm correct trustwords/PGP fingerprint")
        confirmButton.setTitle(confirmTitle, for: .normal)
        confirmButton.pEpIfyForTrust(backgroundColor: .pEpGreen, textColor: .white)
        
        //Decline Button
        let declineTitle = NSLocalizedString("Decline", comment: "Incorrect trustwords/PGP fingerprint")
        declineButton.setTitle(declineTitle, for: .normal)
        declineButton.pEpIfyForTrust(backgroundColor: .pEpRed, textColor: .white)

        //Reset Button
        resetButton.pEpIfyForTrust(backgroundColor: .pEpGrayBackgroundReset, textColor: .white)
     
        //Reset label
        resetLabel.text = NSLocalizedString("Reset all pEp data for this comunication partner:",
                                            comment: "Reset all pEp data for this comunication partner:")
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
