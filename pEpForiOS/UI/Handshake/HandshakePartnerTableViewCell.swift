//
//  HandshakePartnerTableViewCell.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 20.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

/**
 That delegate is in control to handle the actual trust changes.
 */
protocol HandshakePartnerTableViewCellDelegate: class {
    func startStopTrusting(sender: UIButton, cell: HandshakePartnerTableViewCell,
                           indexPath: IndexPath,
                           viewModel: HandshakePartnerTableViewCellViewModel?)
    func confirmTrust(sender: UIButton,  cell: HandshakePartnerTableViewCell,
                      indexPath: IndexPath,
                      viewModel: HandshakePartnerTableViewCellViewModel?)
    func denyTrust(sender: UIButton,  cell: HandshakePartnerTableViewCell,
                   indexPath: IndexPath,
                   viewModel: HandshakePartnerTableViewCellViewModel?)
}

class HandshakePartnerTableViewCell: UITableViewCell {
    /**
     Programmatically created constraints for expanding elements of thes cell,
     depending on state changes.
     */
    struct Constraints {
        /** For expanding the explanation */
        let explanationHeightZero: NSLayoutConstraint

        /** For hiding the start/stop trust button */
        let startStopTrustingHeightZero: NSLayoutConstraint

        /** For hiding trust/mistrust buttons */
        let confirmTrustHeightZero: NSLayoutConstraint

        /** For hiding trustwords label */
        let trustWordsLabelHeightZero: NSLayoutConstraint

        /** For hiding the whole view dealing with trustwords */
        let trustWordsViewHeightZero: NSLayoutConstraint
    }

    @IBOutlet weak var startStopTrustingButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var wrongButton: UIButton!
    @IBOutlet weak var partnerImageView: UIImageView!
    @IBOutlet weak var pEpStatusImageView: UIImageView!
    @IBOutlet weak var partnerNameLabel: UILabel!
    @IBOutlet weak var privacyStatusTitle: UILabel!
    @IBOutlet weak var privacyStatusDescription: UILabel!
    @IBOutlet weak var trustWordsLabel: UILabel!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var trustWordsView: UIView!

    weak var delegate: HandshakePartnerTableViewCellDelegate?

    var indexPath: IndexPath = IndexPath()

    /**
     The additional constraints we have to deal with.
     */
    var additionalConstraints: Constraints?

    var viewModel: HandshakePartnerTableViewCellViewModel? {
        didSet {
            updateView()
            viewModel?.partnerImage.observe() { [weak self] img in
                self?.partnerImageView.image = img
            }
        }
    }

    var rating: PEP_rating { return viewModel?.rating ?? PEP_rating_undefined }

    var showStopStartTrustButton: Bool {
        return viewModel?.identityState.showStopStartTrustButton ?? false
    }

    var showTrustwords: Bool {
        return viewModel?.showTrustwords ?? false
    }

    var backgroundColorDark: Bool {
        return viewModel?.backgroundColorDark ?? false
    }

    var expandedState: HandshakePartnerTableViewCellViewModel.ExpandedState {
        get {
            return viewModel?.expandedState ?? .notExpanded
        }
        set {
            viewModel?.expandedState = newValue
        }
    }

    override func awakeFromNib() {
        startStopTrustingButton.pEpIfyForTrust(backgroundColor: UIColor.pEpYellow, textColor: .black)
        confirmButton.pEpIfyForTrust(backgroundColor: UIColor.pEpGreen, textColor: .white)
        wrongButton.pEpIfyForTrust(backgroundColor: UIColor.pEpRed, textColor: .white)
        setupAdditionalConstraints()
        setNeedsLayout()
    }

    func setupAdditionalConstraints() {
        if additionalConstraints == nil {
            let explanationHeightZero = privacyStatusDescription.heightAnchor.constraint(
                equalToConstant: 0)
            let startStopTrustingHeightZero = startStopTrustingButton.heightAnchor.constraint(
                equalToConstant: 0)

            let confirmTrustHeightZero = confirmButton.heightAnchor.constraint(equalToConstant: 0)
            let trustWordsLabelHeightZero = trustWordsLabel.heightAnchor.constraint(
                equalToConstant: 0)
            let trustWordsViewHeightZero = trustWordsView.heightAnchor.constraint(
                equalToConstant: 0)

            additionalConstraints = Constraints(
                explanationHeightZero: explanationHeightZero,
                startStopTrustingHeightZero: startStopTrustingHeightZero,
                confirmTrustHeightZero: confirmTrustHeightZero,
                trustWordsLabelHeightZero: trustWordsLabelHeightZero,
                trustWordsViewHeightZero: trustWordsViewHeightZero)
        }
    }

    func updateView() {
        if backgroundColorDark {
            headerView.backgroundColor = UIColor.pEpLightBackground
        } else {
            headerView.backgroundColor = UIColor.white
        }
        partnerNameLabel.text = viewModel?.partnerName
        updateStopTrustingButtonTitle()
        updatePrivacyStatus(rating: rating)
        trustWordsLabel.text = viewModel?.trustwords
        partnerImageView.image = viewModel?.partnerImage.value
        updateAdditionalConstraints()
    }

    func updateAdditionalConstraints() {
        updateStartStopTrustingButtonConstraints()
        updateExplanationExpansionConstraints()
        updateTrustwordsExpansionConstraints()
    }

    func updateStartStopTrustingButtonConstraints() {
        if let constraints = additionalConstraints {
            // Hide the stop/start trust button for states other than
            // .mistrusted an .secureAndTrusted.
            constraints.startStopTrustingHeightZero.isActive = !showStopStartTrustButton
            startStopTrustingButton.isHidden = !showStopStartTrustButton
        }
    }

    func updateExplanationExpansionConstraints() {
        if let constraints = additionalConstraints {
            constraints.explanationHeightZero.isActive = expandedState == .notExpanded
        }
    }

    func updateTrustwordsExpansionConstraints() {
        if let constraints = additionalConstraints {
            constraints.confirmTrustHeightZero.isActive = !showTrustwords
            constraints.trustWordsLabelHeightZero.isActive = !showTrustwords
            constraints.trustWordsViewHeightZero.isActive = !showTrustwords
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

        if viewModel?.identityState == .mistrusted {
            startStopTrustingButton.setTitle(titleMistrusted, for: .normal)
        } else {
            startStopTrustingButton.setTitle(titleTrusted, for: .normal)
        }
    }

    func updatePrivacyStatus(rating: PEP_rating) {
        let pEpStatus = String.pEpRatingTranslation(pEpRating: rating)
        privacyStatusTitle.text = pEpStatus.title
        privacyStatusDescription.text = pEpStatus.explanation
        pEpStatusImageView.image = rating.statusIcon()
    }

    func didChangeSelection() {
        if expandedState == .expanded {
            expandedState = .notExpanded
        } else {
            expandedState = .expanded
        }
        updateExplanationExpansionConstraints()
        UIView.animate(withDuration: 0.3) {
            self.contentView.layoutIfNeeded()
        }
    }

    // MARK: - Actions

    @IBAction func startStopTrustingAction(_ sender: UIButton) {
        delegate?.startStopTrusting(sender: sender, cell: self, indexPath: indexPath,
                                    viewModel: viewModel)
    }

    @IBAction func confirmAction(_ sender: UIButton) {
        delegate?.confirmTrust(sender: sender, cell: self, indexPath: indexPath,
                               viewModel: viewModel)
    }

    @IBAction func wrongAction(_ sender: UIButton) {
        delegate?.denyTrust(sender: sender, cell: self, indexPath: indexPath,
                            viewModel: viewModel)
    }
}
