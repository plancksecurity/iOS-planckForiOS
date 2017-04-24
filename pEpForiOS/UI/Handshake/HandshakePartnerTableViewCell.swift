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
    /**
     The UI relevant state of the displayed identity.
     Independent of the state of the Identity, you can expand the cell.
     The expanded version will show the explanation.
     */
    enum IdentityState {
        case illegal

        /**
         The identity is mistrusted (red), which means that no trustwords whatsoever
         should be shown. You might be able to expand, which means you see the explanation.
         pEpForIOS-Handshake-Mistrusted.png
         pEpForIOS-Handshake-Mistrusted-ExpandedText.png
         */
        case mistrusted

        /**
         The identity is already secure (yellow, so to speak).
         Again, you can expand the cell, which will show you the explanation.
         */
        case secure

        /**
         The identity is already trusted (green).
         */
        case secureAndTrusted

        static func from(identity: Identity) -> IdentityState {
            let color = identity.pEpColor()
            switch color {
            case PEP_color_red:
                return .mistrusted
            case PEP_color_yellow:
                return .secure
            case PEP_color_green:
                return .secureAndTrusted
            default:
                return .illegal
            }
        }

        var showStopStartTrustButton: Bool {
            return self == .mistrusted || self == .secureAndTrusted
        }
    }

    enum ExpandedState {
        case notExpanded
        case expanded
    }

    struct UIState {
        var expandedState: ExpandedState
        var identityState: IdentityState
    }

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

    var uiState = UIState(expandedState: .notExpanded, identityState: .mistrusted)

    /**
     The additional constraints we have to deal with.
     */
    var additionalConstraints: Constraints?

    override func awakeFromNib() {
        stopTrustingButton.pEpIfyForTrust(backgroundColor: UIColor.pEpYellow, textColor: .black)
        confirmButton.pEpIfyForTrust(backgroundColor: UIColor.pEpGreen, textColor: .white)
        wrongButton.pEpIfyForTrust(backgroundColor: UIColor.pEpRed, textColor: .white)
        setupAdditionalConstraints()
        setNeedsLayout()
    }

    func updateCell(indexPath: IndexPath, message: Message, partner: Identity,
                    session: PEPSession?, imageProvider: IdentityImageProvider) {
        uiState.identityState = IdentityState.from(identity: partner)
        uiState.expandedState = .notExpanded

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

        setNeedsUpdateConstraints()
        updateStopTrustingButtonTitle()
        updatePrivacyStatus(rating: rating)
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

    override func updateConstraints() {
        updateAdditionConstraints()
        super.updateConstraints()
    }

    func updateAdditionConstraints() {
        if let theAdditionalConstraints = additionalConstraints {
            theAdditionalConstraints.explanationHeightZero.isActive =
                uiState.expandedState == .notExpanded

            // Hide the stop/start trust button for states other than
            // .mistrusted an .secureAndTrusted.
            theAdditionalConstraints.stopTrustingHeightZero.isActive =
                !uiState.identityState.showStopStartTrustButton
            stopTrustingButton.isHidden =
                !uiState.identityState.showStopStartTrustButton
        }
    }

    func updateStopTrustingButtonTitle() {
        if !uiState.identityState.showStopStartTrustButton {
            return
        }

        let titleMistrusted = NSLocalizedString(
            "Start Trusting",
            comment: "Stop/trust button in handshake overview")
        let titleTrusted = NSLocalizedString(
            "Stop Trusting",
            comment: "Stop/trust button in handshake overview")

        if uiState.identityState == .mistrusted {
            stopTrustingButton.setTitle(titleMistrusted, for: .normal)
        } else {
            stopTrustingButton.setTitle(titleTrusted, for: .normal)
        }
    }

    func updatePrivacyStatus(rating: PEP_rating) {
        let pEpStatus = String.pEpRatingTranslation(pEpRating: rating)
        privacyStatusTitle.text = pEpStatus.title
        privacyStatusDescription.text = pEpStatus.explanation
    }
}
