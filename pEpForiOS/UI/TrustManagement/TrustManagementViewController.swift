//
//  TrustManagementViewController.swift
//  pEp
//
//  Created by Martin Brude on 05/02/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

/// View Controller to handle the HandshakeView.
class TrustManagementViewController: UIViewController {
    private let onlyMasterCellIdentifier = "TrustManagementTableViewCell_OnlyMaster"
    private let masterAndDetailCellIdentifier = "TrustManagementTableViewCell_Detailed"
    private let resetCellIdentifier = "TrustManagementTableViewResetCell"
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var optionsButton: UIBarButtonItem!

    var viewModel: TrustManagementViewModel? {
        didSet {
            viewModel?.delegate = self
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 400
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("The viewModel must not be nil")
            return
        }
        if (!vm.shouldShowOptionsButton) {
            navigationItem.rightBarButtonItems?.removeAll(where: {$0 == optionsButton})
        } else {
            optionsButton.title = NSLocalizedString("Options", comment: "Options")
        }
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard let vm = viewModel, vm.canUndo() && motion == .motionShake,
            let actionName = vm.revertAction() else { return }
        let title = actionName // this is already localized
        let confirmTitle = NSLocalizedString("OK",
                                             comment: "Yes, undo the recent trust change")
        let cancelTitle = NSLocalizedString("Cancel",
                                            comment: "No, cancel the undo of the recent trust change")
        UIUtils.showTwoButtonAlert(withTitle: title,
                                   cancelButtonText: cancelTitle,
                                   positiveButtonText: confirmTitle,
                                   positiveButtonAction: { [weak vm] in
                                    vm?.handleShakeMotionDidEnd()
                                   },
                                   style: PEPAlertViewController.AlertStyle.undo)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        tableView.reloadData()
    }

    @IBAction private func optionsButtonPressed(_ sender: UIBarButtonItem) {
        presentToogleProtectionActionSheet()
    }

    deinit {
        unregisterNotifications()
    }
}

// MARK: - Private

extension TrustManagementViewController {

    private func setup() {
        registerForNotifications()
        setLeftBarButton()
        setBackgroundColor()
    }
}

// MARK: - UITableViewDataSource

extension TrustManagementViewController : UITableViewDataSource  {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return 0
        }
        return vm.rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return UITableViewCell()
        }
        let row = vm.rows[indexPath.row]

        if row.blockingColor() == .noColor {
            // Cell for reset
            guard let cell = tableView.dequeueReusableCell(withIdentifier: resetCellIdentifier,
                                                           for: indexPath) as? TrustManagementResetTableViewCell
                else {
                    Log.shared.errorAndCrash("No Cell")
                    return UITableViewCell()
            }
            setupCell(cell, forRowAt: indexPath)
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier(forRowAt: indexPath),
                                                           for: indexPath) as? TrustManagementTableViewCell
                else {
                    Log.shared.errorAndCrash("No Cell")
                    return UITableViewCell()
            }
            setupCell(cell, forRowAt: indexPath)


            return cell
        }
    }
}

// MARK: - UIAlertControllers

extension TrustManagementViewController {
    
    /// This should only be used if the flow comes from the Compose View.
    private func presentToogleProtectionActionSheet() {
        guard let viewModel = viewModel else {
            Log.shared.errorAndCrash("View Model must not be nil")
            return
        }
        let alertController = UIUtils.actionSheet()
        let enable = NSLocalizedString("Enable Protection", comment: "Enable Protection")
        let disable = NSLocalizedString("Disable Protection", comment: "Disable Protection")
        let toogleProtectionTitle = viewModel.pEpProtected  ? disable : enable
        let action = UIAlertAction(title: toogleProtectionTitle, style: .default) { (action) in
            viewModel.handleToggleProtectionPressed()
        }
        alertController.addAction(action)
        let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel")
        let cancelAction = UIAlertAction(title:cancelTitle , style: .cancel) { _ in
            alertController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(cancelAction)

        /// A broken contraint comes up, it's a known issue in iOS.
        /// https://github.com/lionheart/openradar-mirror/issues/21120
        if let buttonView = optionsButton.value(forKey: "view") as? UIView {
            alertController.popoverPresentationController?.sourceView = buttonView
            alertController.popoverPresentationController?.sourceRect = buttonView.bounds
        }
        present(alertController, animated: true, completion: nil)
    }
    
    /// Shows an action sheet with languages when the user taps the language button from a cell
    /// - Parameter cell: The cell of the language button tapped.
    private func showLanguagesList(for cell: TrustManagementTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            Log.shared.error("IndexPath not found")
            return
        }
        let alertController = UIUtils.actionSheet()
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        //For every language a row in the action sheet.
        vm.languages { [weak self] langs in
            DispatchQueue.main.async {
                guard let me = self else {
                    // Valid case. We might have been dismissed already.
                    return
                }

                for language in langs {
                    guard let languageName = NSLocale.current.localizedString(forLanguageCode: language)?.capitalized
                        else {
                            Log.shared.debug("Language name not found")
                            break
                    }
                    let action = UIAlertAction(title: languageName, style: .default) { (action) in
                        vm.handleDidSelect(language: language, forRowAt: indexPath)
                    }
                    alertController.addAction(action)
                }

                //For the cancel button another action.
                let cancel = NSLocalizedString("Cancel",
                                               comment: "TrustManagementView: trustword language selector cancel button label")
                let cancelAction = UIAlertAction(title: cancel, style: .cancel) { _ in
                    alertController.dismiss(animated: true, completion: nil)
                }
                cancelAction.accessibilityIdentifier = AccessibilityIdentifier.cancelButton
                alertController.addAction(cancelAction)

                //Ipad behavior.
                alertController.popoverPresentationController?.sourceView = cell.languageButton
                alertController.popoverPresentationController?.sourceRect = cell.languageButton.bounds
                me.present(alertController, animated: true, completion: nil)
            }
        }
    }
}

// MARK: - TrustManagementViewModelDelegate

extension TrustManagementViewController: TrustManagementViewModelDelegate {
    func showResetPartnerKeySuccessfully() {
        let title = NSLocalizedString("Reset Partner's Key", comment: "Reset Partner's Key successfull title")
        let message = NSLocalizedString("You have successfully reset your partner key.", comment: "Reset partners Key feedback messsage ")
        UIUtils.showAlertWithOnlyCloseButton(title: title, message: message)
    }

    func showResetPartnerKeyFailed(forRowAt indexPath: IndexPath) {
        let title = NSLocalizedString("Reset Partner's Key", comment: "Reset Partner's Key failed title")
        let message = NSLocalizedString("An error has occurred reseting your partner's key. Try again or if the problem persist cancel and please contact with an IT Member", comment: "Reset Own Key - Try again message")
        let tryAgainTitle = NSLocalizedString("Try Again", comment: "Try again button title")
        UIUtils.showTwoButtonAlert(withTitle: title, message: message, positiveButtonText: tryAgainTitle) { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.dismissAndPerform {
                guard let vm = me.viewModel else {
                    Log.shared.errorAndCrash("VM not found")
                    return
                }
                vm.handleResetPressed(forRowAt: indexPath)
            }
        }
    }

    func dataChanged(forRowAt indexPath: IndexPath) {
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

    @objc // Is objC because we also call this from the VC as a selector.
    public func reload() {
        UIView.setAnimationsEnabled(false)
        tableView.reloadData()
        UIView.setAnimationsEnabled(true)
    }
}

// MARK: - Back button

extension TrustManagementViewController {
    
    /// Helper method to create and set the back button in the navigation bar.
    private func setLeftBarButton() {
        let title = NSLocalizedString("Message", comment: "TrustManagementView Back Button Title")
        let button = UIButton.backButton(with: title)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 2)
        let action = #selector(backButtonPressed)
        button.addTarget(self, action:action, for: .touchUpInside)
        let leftItem = UIBarButtonItem(customView: button)
        leftItem.accessibilityIdentifier = AccessibilityIdentifier.backButton
        navigationItem.leftBarButtonItem = leftItem
        navigationController?.navigationBar.isTranslucent = false
    }

    @objc private func backButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Notification Center

extension TrustManagementViewController {
    
    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(reload),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }
    
    private func unregisterNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - TrustManagementTableViewCellDelegate & TrustManagementResetTableViewCellDelegate

extension TrustManagementViewController: TrustManagementTableViewCellDelegate, TrustManagementResetTableViewCellDelegate {
    func languageButtonPressed(on cell: TrustManagementTableViewCell) {
        showLanguagesList(for: cell)
    }
    
    func declineButtonPressed(on cell: TrustManagementTableViewCell) {
        guard let viewModel = viewModel else {
            Log.shared.errorAndCrash("TrustManagementViewModel is nil")
            return
        }
        if let indexPath = tableView.indexPath(for: cell) {
            viewModel.handleRejectHandshakePressed(at: indexPath)
        }
    }

    func confirmButtonPressed(on cell: TrustManagementTableViewCell) {
        guard let viewModel = viewModel else {
            Log.shared.errorAndCrash("TrustManagementViewModel is nil")
            return
        }

        if let indexPath = tableView.indexPath(for: cell) {
            viewModel.handleConfirmHandshakePressed(at: indexPath)
        }
    }
    
    func resetButtonPressed(on cell: UITableViewCell) {
        guard let viewModel = viewModel else {
            Log.shared.errorAndCrash("TrustManagementViewModel is nil")
            return
        }
        if let indexPath = tableView.indexPath(for: cell) {
            showResetPartnerKey {
                viewModel.handleResetPressed(forRowAt: indexPath)
            }
        }
    }
    
    func trustwordsLabelPressed(on cell: TrustManagementTableViewCell) {
        guard let viewModel = viewModel else {
            Log.shared.errorAndCrash("TrustManagementViewModel is nil")
            return
        }
        if let indexPath = tableView.indexPath(for: cell) {
            viewModel.handleToggleLongTrustwords(forRowAt: indexPath)
        }
    }
}

// MARK: - Cell configuration

extension TrustManagementViewController {

    /// This method configures the layout for the provided cell.
    /// We use 2 different cells: one for the split view the other for iphone portrait view.
    /// The layout is different, so different UI structures are used.
    /// 
    /// - Parameters:
    ///   - cell: The cell to be configured.
    ///   - indexPath: The indexPath of the row, to get the trustwords.
    private func setupCell(_ cell: TrustManagementTableViewCell, forRowAt indexPath: IndexPath) {
        setBackgroundColor(on: cell)
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        // After all async calls have returend the cell size need update
        let updateSizeGroup = DispatchGroup()
        let row = vm.rows[indexPath.row]

        let identifier = cellIdentifier(forRowAt: indexPath)

        updateSizeGroup.enter()
        vm.getImage(forRowAt: indexPath) { (image) in
            cell.partnerImageView.image = image
            updateSizeGroup.leave()
        }
        updateSizeGroup.enter()
        row.privacyStatusImage { (image) in
            cell.privacyStatusImageView.image = image
            updateSizeGroup.leave()
        }
        cell.partnerNameLabel.text = row.name
        updateSizeGroup.enter()
        row.privacyStatusName { (name) in
            cell.privacyStatusLabel.text = name
            updateSizeGroup.leave()
        }
        updateSizeGroup.enter()
        row.description { (description) in
            cell.descriptionLabel.text = description
            updateSizeGroup.leave()
        }
        updateSizeGroup.enter()
        row.color { [weak self] (rowColor) in
            defer { updateSizeGroup.leave() }
            guard let me = self else {
                // Valid case. We might have been dismissed already.
                return
            }
            //Yellow means secure but not trusted.
            //That means that's the only case must display the trustwords
            if identifier == me.onlyMasterCellIdentifier {
                if rowColor == .yellow {
                    cell.trustwordsLabel.text = row.trustwords
                    cell.trustwordsStackView.isHidden = false
                    cell.trustwordsButtonsContainer.isHidden = false

                    cell.ownFingerprintTitleLabel.text = row.ownTitle
                    cell.ownFingerprintLabel.text = row.ownFormattedFingerprint

                    cell.partnerFingerprintTitleLabel.text = row.partnerTitle
                    cell.partnerFingerprintLabel.text = row.partnerFormattedFingerprint
                } else {
                    cell.trustwordsStackView.isHidden = true
                    cell.trustwordsButtonsContainer.isHidden = true
                }
            } else if identifier == me.masterAndDetailCellIdentifier {
                if rowColor == .yellow {
                    cell.trustwordsLabel.text = row.trustwords
                    cell.trustwordsLabel.isHidden = false
                    cell.confirmButton.isHidden = false
                    cell.declineButton.isHidden = false
                    cell.languageButton.isHidden = false
                } else {
                    cell.languageButton.isHidden = true
                    cell.trustwordsLabel.isHidden = true
                    cell.confirmButton.isHidden = true
                    cell.declineButton.isHidden = true
                }
            }
        }
        updateSizeGroup.notify(queue: DispatchQueue.main) { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.tableView.updateSize()
        }
        cell.delegate = self
    }

    private func setupCell(_ cell: TrustManagementResetTableViewCell, forRowAt indexPath: IndexPath) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        setBackgroundColor(on: cell)
        // After all async calls have returend the cell size need update
        let updateSizeGroup = DispatchGroup()
           guard let row = viewModel?.rows[indexPath.row] else {
               Log.shared.errorAndCrash("No Row")
               return
           }
        cell.delegate = self
        cell.partnerNameLabel.text = row.name
        updateSizeGroup.enter()
        vm.getImage(forRowAt: indexPath) { (image) in
            cell.partnerImageView.image = image
            updateSizeGroup.leave()
        }
        updateSizeGroup.notify(queue: DispatchQueue.main) { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.tableView.updateSize()
        }
    }

    private func cellIdentifier(forRowAt indexpath: IndexPath) -> String {
        let identifier : String
        if UIDevice.current.orientation.isLandscape ||
            UIDevice.current.userInterfaceIdiom == .pad {
            identifier = masterAndDetailCellIdentifier
        } else {
            identifier = onlyMasterCellIdentifier
        }
        return identifier
    }
}

// MARK: - Trait Collection

extension TrustManagementViewController {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let thePreviousTraitCollection = previousTraitCollection else {
            // Valid case: optional value from Apple.
            return
        }
        if thePreviousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) {
            setBackgroundColor()
            IdentityImageTool.clearCache()
            loadView() //Needed to re-load reset button.
            tableView.reloadData()
        }
    }
}

// MARK: - Background Color

extension TrustManagementViewController {

    private func setBackgroundColor() {
        setBackgroundColor(onView: tableView)
    }

    private func setBackgroundColor(on cell: UITableViewCell) {
        setBackgroundColor(onView: cell)
    }

    private func setBackgroundColor(onView view: UIView) {
        if UITraitCollection.current.userInterfaceStyle == .light {
            view.backgroundColor = .white
        } else {
            view.backgroundColor = .secondarySystemBackground
        }
    }
}

//MARK: - Reset Partner Key

extension TrustManagementViewController {

    private func showResetPartnerKey(callback: @escaping TrustManagementViewModel.ActionBlock) {
        let title = NSLocalizedString("Reset Partner Key", comment: "Confirm to Reset Partner Key title alert")

        let message = NSLocalizedString("""
        Resetting the public key of a recipient will clear the link between that key and the recipient's key from your database.

        After resetting and as soon as you start composing an email to the recipient, p≡p will automatically get the correct public key.
        """, comment: "Reset partner key pop up message")
        let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel reset account identity button title")
        let resetTitle = NSLocalizedString("Yes, Reset", comment: "Reset account identity button title")
        UIUtils.showTwoButtonAlert(withTitle: title,
                                   message: message,
                                   cancelButtonText: cancelTitle,
                                   positiveButtonText: resetTitle,
                                   positiveButtonAction: { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.dismissAndPerform {
                callback()
            }

        },
        style: PEPAlertViewController.AlertStyle.warn)
    }
}
