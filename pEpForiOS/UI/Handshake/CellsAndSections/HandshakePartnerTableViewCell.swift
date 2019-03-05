//
//  HandshakePartnerTableViewCell.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 20.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox
import MessageModel

/**
 That delegate is in control to handle the actual trust changes.
 */
protocol HandshakePartnerTableViewCellDelegate: class {
    func resetTrustOrUndoMistrust(sender: UIButton, cell: HandshakePartnerTableViewCell,
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
    func updateSize()
}

class HandshakePartnerTableViewCell: UITableViewCell {
    @IBOutlet weak var startStopTrustingButton: UIButton!
    @IBOutlet weak var confirmButton: HandshakeButton!
    @IBOutlet weak var wrongButton: HandshakeButton!
    @IBOutlet weak var partnerImageView: UIImageView!
    @IBOutlet weak var pEpStatusImageView: UIImageView!
    @IBOutlet weak var partnerNameLabel: UILabel!
    @IBOutlet weak var privacyStatusTitle: UILabel!
    @IBOutlet weak var privacyStatusDescription: UILabel!
    @IBOutlet weak var trustWordsLabel: UILabel!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var trustWordsView: UIView!
    @IBOutlet weak var trustMistrustButtonsStackView: UIStackView!

    var sizeHelper = false

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

    var partnerColor: PEPColor { return viewModel?.partnerColor ?? PEPColor.noColor }

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

    var isPartnerPEPUser: Bool {
        return viewModel?.isPartnerpEpUser ?? false
    }

    var trustwordsFull: Bool {
        return viewModel?.trustwordsFull ?? false
    }

    override func awakeFromNib() {
        updateConfirmDistrustButtonsTitle()
        trustWordsLabel.preferredMaxLayoutWidth = self.bounds.width
        startStopTrustingButton.pEpIfyForTrust(backgroundColor: UIColor.pEpYellow,
                                               textColor: .black)
        wrongButton.pEpIfyForTrust(backgroundColor: UIColor.pEpRed, textColor: .white)
        confirmButton.pEpIfyForTrust(backgroundColor: UIColor.pEpGreen, textColor: .white)

    }

    override func layoutSubviews() {
        super.layoutSubviews()

        confirmButton.roundCorners(corners: [.bottomRight, .topRight], radius: 10)
        wrongButton.roundCorners(corners: [.topLeft, .bottomLeft], radius: 10)
        startStopTrustingButton.layer.cornerRadius = 10
    }

    func updateView() {
        if backgroundColorDark {
            self.backgroundColor = UIColor.pEpLightBackground
        } else {
            self.backgroundColor = UIColor.white
        }
        partnerNameLabel.text = viewModel?.partnerName
        updateStopTrustingButtonTitle()
        updatePrivacyStatus(color: partnerColor)
        updateTrustwords()
        partnerImageView.image = viewModel?.partnerImage.value

        trustWordsLabel.isUserInteractionEnabled = isPartnerPEPUser

        if isPartnerPEPUser && showTrustwords {
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
        let showElipsis = isPartnerPEPUser && !trustwordsFull
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
        privacyStatusDescription.isHidden = expandedState == .notExpanded
    }

    func updateTrustwordsExpansionVisibility() {
        trustWordsLabel.isHidden = !showTrustwords
        trustMistrustButtonsStackView.isHidden = !showTrustwords
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

        if viewModel?.partnerColor == PEPColor.red ||
            viewModel?.partnerRating == .haveNoKey {
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
            if !isPartnerPEPUser {
                button.setTitle(confirmPGPLong, for: .normal)
            } else {
                button.setTitle(confirmLong, for: .normal)
            }
        } else if button == wrongButton {
            if !isPartnerPEPUser {
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

    func updatePrivacyStatus(color: PEPColor) {
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
        //UIView.animate(withDuration: 0.3) {
            self.contentView.layoutIfNeeded()
        //}
    }

    // MARK: - Gestures

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
        delegate?.resetTrustOrUndoMistrust(sender: sender, cell: self, indexPath: indexPath,
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
