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
    struct Constraints {
        var explanationHeightZero: NSLayoutConstraint
        var stopTrustingHeightZero: NSLayoutConstraint
    }

    @IBOutlet weak var stopTrustingButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var wrongButton: UIButton!
    @IBOutlet weak var partnerImageView: UIImageView!
    @IBOutlet weak var pEpStatusImageView: UIImageView!
    @IBOutlet weak var partnerNameLabel: UILabel!
    @IBOutlet weak var privacyStatusTitle: UILabel!
    @IBOutlet weak var privacyStatusDescription: UILabel!
    @IBOutlet weak var trustWordsLabel: UILabel!
    @IBOutlet weak var headerView: UIView!

    /**
     The additional constraints we have to deal with.
     */
    var additionalConstraints: Constraints?

    var uiState: HandshakePartnerTableViewCellUIState? {
        didSet {
            updateView()
        }
    }

    var rating: PEP_rating { return uiState?.rating ?? PEP_rating_undefined }
    var showStopStartTrustButton: Bool {
        return uiState?.identityState.showStopStartTrustButton ?? false
    }
    var expandedState: HandshakePartnerTableViewCellUIState.ExpandedState {
        get {
            return uiState?.expandedState ?? .notExpanded
        }
        set {
            uiState?.expandedState = newValue
        }
    }

    override func awakeFromNib() {
        stopTrustingButton.pEpIfyForTrust(backgroundColor: UIColor.pEpYellow, textColor: .black)
        confirmButton.pEpIfyForTrust(backgroundColor: UIColor.pEpGreen, textColor: .white)
        wrongButton.pEpIfyForTrust(backgroundColor: UIColor.pEpRed, textColor: .white)
        setupAdditionalConstraints()
        setNeedsLayout()
    }

    func setupAdditionalConstraints() {
        if additionalConstraints == nil {
            let explanationHeightZero = privacyStatusDescription.heightAnchor.constraint(
                equalToConstant: 0)
            let stopTrustingHeightZero = stopTrustingButton.heightAnchor.constraint(
                equalToConstant: 0)
            additionalConstraints = Constraints(
                explanationHeightZero: explanationHeightZero,
                stopTrustingHeightZero: stopTrustingHeightZero)
        }
    }

    func updateView() {
        updateStopTrustingButtonTitle()
        updatePrivacyStatus(rating: rating)
        trustWordsLabel.text = uiState?.trustwords
        partnerImageView.image = uiState?.partnerImage
        updateAdditionalConstraints()
    }

    func updateAdditionalConstraints() {
        if let theAdditionalConstraints = additionalConstraints {
            // Hide the stop/start trust button for states other than
            // .mistrusted an .secureAndTrusted.
            theAdditionalConstraints.stopTrustingHeightZero.isActive = !showStopStartTrustButton
            stopTrustingButton.isHidden = !showStopStartTrustButton

            updateExpansionConstraints()
        }
    }

    func updateStopTrustingButtonTitle() {
        if !showStopStartTrustButton {
            return
        }

        let titleMistrusted = NSLocalizedString(
            "Start Trusting",
            comment: "Stop/trust button in handshake overview")
        let titleTrusted = NSLocalizedString(
            "Stop Trusting",
            comment: "Stop/trust button in handshake overview")

        if uiState?.identityState == .mistrusted {
            stopTrustingButton.setTitle(titleMistrusted, for: .normal)
        } else {
            stopTrustingButton.setTitle(titleTrusted, for: .normal)
        }
    }

    func updatePrivacyStatus(rating: PEP_rating) {
        let pEpStatus = String.pEpRatingTranslation(pEpRating: rating)
        privacyStatusTitle.text = pEpStatus.title
        privacyStatusDescription.text = pEpStatus.explanation
        pEpStatusImageView.image = rating.statusIcon()
    }

    func updateExpansionConstraints() {
        if let theAdditionalConstraints = additionalConstraints {
            theAdditionalConstraints.explanationHeightZero.isActive = expandedState == .notExpanded
        }
    }

    func didChangeSelection() {
        if expandedState == .expanded {
            expandedState = .notExpanded
        } else {
            expandedState = .expanded
        }
        updateExpansionConstraints()
        UIView.animate(withDuration: 0.3) {
            self.contentView.layoutIfNeeded()
        }
    }
}
