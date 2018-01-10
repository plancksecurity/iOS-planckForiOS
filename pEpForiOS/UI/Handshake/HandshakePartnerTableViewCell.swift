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
    func resetTrust(sender: UIButton, cell: HandshakePartnerTableViewCell,
                    indexPath: IndexPath,
                    viewModel: HandshakePartnerTableViewCellViewModel?)

    func confirmTrust(sender: UIButton,  cell: HandshakePartnerTableViewCell,
                      indexPath: IndexPath,
                      viewModel: HandshakePartnerTableViewCellViewModel?)

    func denyTrust(sender: UIButton,  cell: HandshakePartnerTableViewCell,
                   indexPath: IndexPath,
                   viewModel: HandshakePartnerTableViewCellViewModel?)

    func pickLanguage(sender: UIView,  cell: HandshakePartnerTableViewCell,
                      indexPath: IndexPath,
                      viewModel: HandshakePartnerTableViewCellViewModel?)

    func toggleTrustwordsLength(sender: UIView,  cell: HandshakePartnerTableViewCell,
                                indexPath: IndexPath,
                                viewModel: HandshakePartnerTableViewCellViewModel?)
}

class HandshakePartnerTableViewCell: UITableViewCell {
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
    @IBOutlet weak var languageSelectorImageView: UIImageView!

    weak var delegate: HandshakePartnerTableViewCellDelegate?

    var indexPath: IndexPath = IndexPath()

    var viewModel: HandshakePartnerTableViewCellViewModel? {
        didSet {
            updateView()
            viewModel?.partnerImage.observe() { [weak self] img in
                self?.partnerImageView.image = img
            }
        }
    }

    var identityColor: PEP_color { return viewModel?.identityColor ?? PEP_color_no_color }

    var showStopStartTrustButton: Bool {
        return viewModel?.showStopStartTrustButton ?? false
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

    var isPartnerPGPUser: Bool {
        return viewModel?.isPartnerPGPUser ?? false
    }

    var trustwordsFull: Bool {
        return viewModel?.trustwordsFull ?? false
    }

    let boundsWidthKeyPath = "bounds"

    var buttonsFitWidth = [(Tuple<UIButton, CGFloat>): Bool]()


    override func awakeFromNib() {
        updateConfirmDistrustButtonsTitle()

        startStopTrustingButton.pEpIfyForTrust(backgroundColor: UIColor.pEpYellow,
                                               textColor: .black)
        confirmButton.pEpIfyForTrust(backgroundColor: UIColor.pEpGreen, textColor: .white)
        wrongButton.pEpIfyForTrust(backgroundColor: UIColor.pEpRed, textColor: .white)

        setNeedsLayout()
    }

    func updateView() {
        if backgroundColorDark {
            headerView.backgroundColor = UIColor.pEpLightBackground
        } else {
            headerView.backgroundColor = UIColor.white
        }
        partnerNameLabel.text = viewModel?.partnerName
        updateStopTrustingButtonTitle()
        updatePrivacyStatus(color: identityColor)
        updateTrustwords()
        partnerImageView.image = viewModel?.partnerImage.value

        languageSelectorImageView.isUserInteractionEnabled = !isPartnerPGPUser
        trustWordsLabel.isUserInteractionEnabled = !isPartnerPGPUser

        languageSelectorImageView.isHidden = isPartnerPGPUser
        if !isPartnerPGPUser && showTrustwords {
            install(gestureRecognizer: UITapGestureRecognizer(
                target: self,
                action: #selector(languageSelectorAction(_:))),
                    view: languageSelectorImageView)

            install(gestureRecognizer: UITapGestureRecognizer(
                target: self,
                action: #selector(toggleTrustwordsLengthAction(_:))),
                    view: trustWordsLabel)
        }

        updateStopTrustingButtonTitle()

        updateConfirmDistrustButtonsTitle()

        updateAdditionalConstraints()
    }

    /**
     Installs a gesture recognizer on a view, removing all previously existing ones.
     */
    func install(gestureRecognizer: UIGestureRecognizer, view: UIView) {
        // rm all exsting
        let existingGRs = view.gestureRecognizers ?? []
        for gr in existingGRs {
            view.removeGestureRecognizer(gr)
        }
        view.addGestureRecognizer(gestureRecognizer)
    }

    func updateTrustwords() {
        let showElipsis = !isPartnerPGPUser && !trustwordsFull
        if showElipsis,
            let trustwords = viewModel?.trustwords {
            trustWordsLabel.text = "\(trustwords) …"
        } else {
            trustWordsLabel.text = viewModel?.trustwords
        }
    }

    func updateAdditionalConstraints() {
        updateStartStopTrustingButtonVisibility()
        updateExplanationExpansionVisibility()
        updateTrustwordsExpansionVisibility()
    }

    func updateStartStopTrustingButtonVisibility() {
        startStopTrustingButton.isHidden = !showStopStartTrustButton
    }

    func updateExplanationExpansionVisibility() {
        privacyStatusDescription.isHidden = expandedState == .expanded
    }

    func updateTrustwordsExpansionVisibility() {
        trustWordsView.isHidden = !showTrustwords
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

        if viewModel?.identityColor == PEP_color_red {
            startStopTrustingButton.setTitle(titleMistrusted, for: .normal)
        } else {
            startStopTrustingButton.setTitle(titleTrusted, for: .normal)
        }
    }

    func updateTitle(button: UIButton) {
        let confirmPGPLong =
            NSLocalizedString("Confirm Fingerprint",
                              comment: "Confirm correct fingerprint (PGP, long version)")
        let mistrustPGPLong =
            NSLocalizedString("Wrong Fingerprint",
                              comment: "Incorrect fingerprint (PGP, long version)")
        let confirmLong =
            NSLocalizedString("Confirm Trustwords",
                              comment: "Confirm correct trustwords (pEp, long version)")
        let mistrustLong =
            NSLocalizedString("Wrong Trustwords",
                              comment: "Incorrect trustwords (pEp, long version)")

        if button == confirmButton {
            if isPartnerPGPUser {
                button.setTitle(confirmPGPLong, for: .normal)
            } else {
                button.setTitle(confirmLong, for: .normal)
            }
        } else if button == wrongButton {
            if isPartnerPGPUser {
                button.setTitle(mistrustPGPLong, for: .normal)
            } else {
                button.setTitle(mistrustLong, for: .normal)
            }
        }
    }

    func updateConfirmDistrustButtonsTitle() {
        updateTitle(button: confirmButton)
        updateTitle(button: wrongButton)
    }

    func updatePrivacyStatus(color: PEP_color) {
        privacyStatusTitle.text = color.privacyStatusTitle
        privacyStatusDescription.text = color.privacyStatusDescription
        pEpStatusImageView.image = color.statusIcon()
    }

    func didChangeSelection() {
        if expandedState == .expanded {
            expandedState = .notExpanded
        } else {
            expandedState = .expanded
        }
        updateExplanationExpansionVisibility()
        UIView.animate(withDuration: 0.3) {
            self.contentView.layoutIfNeeded()
        }
    }

    // MARK: - Gestures

    @objc func languageSelectorAction(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            delegate?.pickLanguage(
                sender: gestureRecognizer.view ?? languageSelectorImageView,
                cell: self,
                indexPath: indexPath,
                viewModel: viewModel)
        }
    }

    @objc func toggleTrustwordsLengthAction(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            delegate?.toggleTrustwordsLength(
                sender: gestureRecognizer.view ?? trustWordsLabel,
                cell: self,
                indexPath: indexPath,
                viewModel: viewModel)
        }
    }

    // MARK: - Actions

    @IBAction func startStopTrustingAction(_ sender: UIButton) {
        delegate?.resetTrust(sender: sender, cell: self, indexPath: indexPath,
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
