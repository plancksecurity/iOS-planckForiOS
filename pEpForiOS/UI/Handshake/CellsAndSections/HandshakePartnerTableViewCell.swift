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
import PEPObjCAdapterFramework

/**
 That delegate is in control to handle the actual trust changes.
 */
protocol HandshakePartnerTableViewCellDelegate: class {
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
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var wrongButton: UIButton!
    @IBOutlet weak var partnerImageView: UIImageView!
    @IBOutlet weak var pEpStatusImageView: UIImageView!
    @IBOutlet weak var partnerNameLabel: UILabel!
    @IBOutlet weak var privacyStatusTitle: UILabel!
    @IBOutlet weak var privacyStatusDescription: UILabel!
    @IBOutlet weak var trustWordsLabel: UILabel!
    @IBOutlet weak var trustMistrustButtonsStackView: UIStackView!

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

    private var partnerColor: PEPColor { return viewModel?.partnerColor ?? PEPColor.noColor }

    private var showStopStartTrustButton: Bool {
        return viewModel?.showStopStartTrustButton ?? false
    }

    private var showTrustwords: Bool {
        return viewModel?.showTrustwords ?? false
    }

    private var backgroundColorDark: Bool {
        return viewModel?.backgroundColorDark ?? false
    }

    private var isPartnerPEPUser: Bool {
        return viewModel?.isPartnerpEpUser ?? false
    }

    private var trustwordsFull: Bool {
        return viewModel?.trustwordsFull ?? false
    }

    override func awakeFromNib() {
        updateConfirmDistrustButtonsTitle()
        wrongButton.pEpIfyForTrust(backgroundColor: UIColor.pEpRed, textColor: .white)
        confirmButton.pEpIfyForTrust(backgroundColor: UIColor.pEpGreen, textColor: .white)
        addMultilineButtonConstraints(button: wrongButton)
        addMultilineButtonConstraints(button: confirmButton)
    }

    /// Adds vertical constraints so a button respects the content height of its label
    /// with respect to laying itself out,
    /// even if that label is wrapping into an additional line.
    ///
    /// Without this, multiline UIButtons tend to cut off parts of the inner content
    /// instead of pushing to expand, even with higher compression resistance.
    private func addMultilineButtonConstraints(button: UIButton) {
        if let label = button.titleLabel {
            button.heightAnchor.constraint(greaterThanOrEqualTo: label.heightAnchor).isActive = true
        }
    }

    private func updateView() {
        if backgroundColorDark {
            self.backgroundColor = UIColor.pEpLightBackground
        } else {
            self.backgroundColor = UIColor.white
        }
        partnerNameLabel.text = viewModel?.partnerName
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

        updateConfirmDistrustButtonsTitle()

        updateAdditionalConstraints()
    }

    /**
     Installs a gesture recognizer on a view, removing all previously existing ones.
     */
    private func install(gestureRecognizer: UIGestureRecognizer, view: UIView) {
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

    private func updateAdditionalConstraints() {
        updateTrustwordsExpansionVisibility()
    }

    private func updateTrustwordsExpansionVisibility() {
        trustWordsLabel.isHidden = !showTrustwords
        trustMistrustButtonsStackView.isHidden = !showTrustwords
    }

    private func updateTitle(button: UIButton) {
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

    private func updateConfirmDistrustButtonsTitle() {
        updateTitle(button: confirmButton)
        updateTitle(button: wrongButton)
    }

    private func updatePrivacyStatus(color: PEPColor) {
        if color == .noColor {
            privacyStatusDescription.text = nil
            pEpStatusImageView.image = nil
        } else {
            privacyStatusDescription.text = color.privacyStatusDescription
            pEpStatusImageView.image = color.statusIconForMessage()
        }

        let privacyStatus = NSLocalizedString("Privacy Status",
                                              comment: "Privacy status title part in handshake list")
        privacyStatusTitle.text = "\(privacyStatus): \(color.privacyStatusTitle)"
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

    @IBAction func confirmAction(_ sender: UIButton) {
        delegate?.confirmTrust(sender: sender, cell: self, indexPath: indexPath,
                               viewModel: viewModel)
    }

    @IBAction func wrongAction(_ sender: UIButton) {
        delegate?.denyTrust(sender: sender, cell: self, indexPath: indexPath,
                            viewModel: viewModel)
    }
}
