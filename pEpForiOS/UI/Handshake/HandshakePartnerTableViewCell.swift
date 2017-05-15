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

    func pickLanguage(sender: UIView,  cell: HandshakePartnerTableViewCell,
                      indexPath: IndexPath,
                      viewModel: HandshakePartnerTableViewCellViewModel?)

    func toggleTrustwordsLength(sender: UIView,  cell: HandshakePartnerTableViewCell,
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

        let privacyStatusTitleBottom: NSLayoutConstraint
        let privacyStatusDescriptionBottom: NSLayoutConstraint
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
    @IBOutlet weak var languageSelectorImageView: UIImageView!

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
    var buttonsUsingLongTitle = [UIButton: Bool]()


    override func awakeFromNib() {
        updateConfirmDistrustButtonsTitle(useLongTitles: true)

        startStopTrustingButton.pEpIfyForTrust(backgroundColor: UIColor.pEpYellow,
                                               textColor: .black)
        confirmButton.pEpIfyForTrust(backgroundColor: UIColor.pEpGreen, textColor: .white)
        wrongButton.pEpIfyForTrust(backgroundColor: UIColor.pEpRed, textColor: .white)
        setupAdditionalConstraints()

        confirmButton.addObserver(self, forKeyPath: boundsWidthKeyPath,
                                  options: [.old, .new],
                                  context: nil)
        wrongButton.addObserver(self, forKeyPath: boundsWidthKeyPath,
                                options: [.old, .new],
                                context: nil)

        setNeedsLayout()
    }

    deinit {
        confirmButton.removeObserver(self, forKeyPath: boundsWidthKeyPath)
        wrongButton.removeObserver(self, forKeyPath: boundsWidthKeyPath)
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

            let defaultYMargin: CGFloat = 16
            let privacyStatusTitleBottom = privacyStatusTitle.bottomAnchor.constraint(
                equalTo: headerView.bottomAnchor, constant: -defaultYMargin)
            let privacyStatusDescriptionBottom = privacyStatusDescription.bottomAnchor.constraint(
                equalTo: headerView.bottomAnchor, constant: -defaultYMargin)

            additionalConstraints = Constraints(
                explanationHeightZero: explanationHeightZero,
                startStopTrustingHeightZero: startStopTrustingHeightZero,
                confirmTrustHeightZero: confirmTrustHeightZero,
                trustWordsLabelHeightZero: trustWordsLabelHeightZero,
                trustWordsViewHeightZero: trustWordsViewHeightZero,
                privacyStatusTitleBottom: privacyStatusTitleBottom,
                privacyStatusDescriptionBottom: privacyStatusDescriptionBottom)
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
        updatePrivacyStatus(color: identityColor)
        updateTrustwords()
        partnerImageView.image = viewModel?.partnerImage.value

        languageSelectorImageView.isUserInteractionEnabled = !isPartnerPGPUser
        trustWordsLabel.isUserInteractionEnabled = !isPartnerPGPUser

        if isPartnerPGPUser {
            languageSelectorImageView.image = nil
        } else {
            languageSelectorImageView.image = UIImage(named: "grid-globe")

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

        let useLong = (buttonsUsingLongTitle[confirmButton] ?? true) ||
            (buttonsUsingLongTitle[wrongButton] ?? true)
        updateConfirmDistrustButtonsTitle(useLongTitles: useLong)

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
            trustWordsLabel.text = trustwords + " …"
        } else {
            trustWordsLabel.text = viewModel?.trustwords
        }
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
            constraints.privacyStatusTitleBottom.isActive =
                !showStopStartTrustButton && expandedState == .notExpanded
            constraints.privacyStatusDescriptionBottom.isActive =
                !showStopStartTrustButton && expandedState == .expanded
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

        if viewModel?.identityColor == PEP_color_red {
            startStopTrustingButton.setTitle(titleMistrusted, for: .normal)
        } else {
            startStopTrustingButton.setTitle(titleTrusted, for: .normal)
        }
    }

    func updateTitle(button: UIButton, useLongTitle: Bool) {
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

        let confirmShort =
            NSLocalizedString("Confirm",
                              comment: "Confirm correct trustwords (PGP, pEp, short version)")
        let mistrustShort =
            NSLocalizedString("Wrong",
                              comment: "Incorrect trustwords (PGP, pEp, short version)")
        let confirmPGPShort = confirmShort
        let mistrustPGPShort = mistrustShort

        if button == confirmButton {
            if isPartnerPGPUser {
                if useLongTitle {
                    button.setTitle(confirmPGPLong, for: .normal)
                } else {
                    button.setTitle(confirmPGPShort, for: .normal)
                }
            } else {
                if useLongTitle {
                    button.setTitle(confirmLong, for: .normal)
                } else {
                    button.setTitle(confirmShort, for: .normal)
                }
            }
        } else if button == wrongButton {
            if isPartnerPGPUser {
                if useLongTitle {
                    button.setTitle(mistrustPGPLong, for: .normal)
                } else {
                    button.setTitle(mistrustPGPShort, for: .normal)
                }
            } else {
                if useLongTitle {
                    button.setTitle(mistrustLong, for: .normal)
                } else {
                    button.setTitle(mistrustShort, for: .normal)
                }
            }
        }
        buttonsUsingLongTitle[button] = useLongTitle
    }

    func updateConfirmDistrustButtonsTitle(useLongTitles: Bool = true) {
        updateTitle(button: confirmButton, useLongTitle: useLongTitles)
        updateTitle(button: wrongButton, useLongTitle: useLongTitles)
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
        updateExplanationExpansionConstraints()
        UIView.animate(withDuration: 0.3) {
            self.contentView.layoutIfNeeded()
        }
    }

    // MARK: - Gestures

    func languageSelectorAction(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            delegate?.pickLanguage(
                sender: gestureRecognizer.view ?? languageSelectorImageView,
                cell: self,
                indexPath: indexPath,
                viewModel: viewModel)
        }
    }

    func toggleTrustwordsLengthAction(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            delegate?.toggleTrustwordsLength(
                sender: gestureRecognizer.view ?? trustWordsLabel,
                cell: self,
                indexPath: indexPath,
                viewModel: viewModel)
        }
    }

    // MARK: - Wrap trust buttons around

    override open func observeValue(forKeyPath keyPath: String?, of object: Any?,
                                    change: [NSKeyValueChangeKey : Any]?,
                                    context: UnsafeMutableRawPointer?) {
        if keyPath == boundsWidthKeyPath {
            handleButtonSizeChanged(object: object, change: change, context: context)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change,
                               context: context)
        }
    }

    func handleButtonSizeChanged(object: Any?,
                                 change: [NSKeyValueChangeKey : Any]?,
                                 context: UnsafeMutableRawPointer?) {
        if let oldRect = change?[NSKeyValueChangeKey.oldKey] as? CGRect,
            let newRect = change?[NSKeyValueChangeKey.newKey] as? CGRect,
            newRect.size.width != oldRect.size.width,
            let button = object as? UIButton {
            let newWidth = newRect.size.width

            let usingLongTitle = buttonsUsingLongTitle[button] ?? false
            let shortTitleMightFit = buttonsFitWidth[Tuple(values: (button, newWidth))] ?? true

            if usingLongTitle && !button.contentFitsWidth() {
                // not enought room, switching to the short title might help
                updateTitle(button: button, useLongTitle: false)
                buttonsFitWidth[Tuple(values: (button, newWidth))] = false
            } else if !usingLongTitle && button.contentFitsWidth() && shortTitleMightFit {
                // have room, might use it for the long title
                updateTitle(button: button, useLongTitle: true)
            }
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
