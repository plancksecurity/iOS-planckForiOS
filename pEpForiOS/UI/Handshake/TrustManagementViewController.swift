//
//  TrustManagementViewController.swift
//  pEp
//
//  Created by Martin Brude on 05/02/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

protocol TrustManagementViewControllerDelegate: class {
    func pEpProtectionDidChange(to state: Bool)
}

/// View Controller to handle the HandshakeView.
class TrustManagementViewController: BaseViewController {
    
    var backButtonTitle : String?
    private let onlyMasterCellIdentifier = "TrustManagementTableViewCell_OnlyMaster"
    private let masterAndDetailCellIdentifier = "TrustManagementTableViewCell_Detailed"
    private let resetCellIdentifier = "TrustManagementTableViewResetCell"
    
    @IBOutlet weak var trustManagementTableView: UITableView!
    @IBOutlet weak var optionsButton: UIBarButtonItem!
    var shouldShowOptionsButton: Bool = false
    var viewModel : TrustManagementViewModel?
    weak var optionsDelegate : TrustManagementViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(reload),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)

        guard let viewModel = viewModel else {
            Log.shared.errorAndCrash("The viewModel must not be nil")
            return
        }
        setLeftBarButton()

        if (!shouldShowOptionsButton) {
            navigationItem.rightBarButtonItems?.removeAll(where: {$0 == optionsButton})
        } else {
            optionsButton.title = NSLocalizedString("Options", comment: "Options")
        }
        viewModel.trustManagementViewModelDelegate = self
        trustManagementTableView.rowHeight = UITableView.automaticDimension
        trustManagementTableView.estimatedRowHeight = 400
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard let vm = viewModel, vm.canUndo() && motion == .motionShake,
            let actionName = vm.lastActionPerformed() else { return }
        let title = NSLocalizedString("Undo \(actionName)", comment: "Undo trust change verification alert title")
        let alertController = UIAlertController.pEpAlertController(title: title,
                                                                   message: nil,
                                                                   preferredStyle: .alert)
        let confirmTitle = NSLocalizedString("Undo", comment: "Undo trust change verification button title")
        let action = UIAlertAction(title: confirmTitle, style: .default) { [weak vm] (action) in
            vm?.shakeMotionDidEnd()
        }
        alertController.addAction(action)
        
        //For the cancel button another action.
        let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel trust change to be undone")
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { _ in
            alertController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        trustManagementTableView.reloadData()
    }

    @IBAction private func optionsButtonPressed(_ sender: UIBarButtonItem) {
        presentToogleProtectionActionSheet()
    }
   
    deinit {
        unregisterNotifications()
    }
}

/// MARK: - UITableViewDataSource

extension TrustManagementViewController : UITableViewDataSource  {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let numberOfRows = viewModel?.rows.count else {
            Log.shared.error("The viewModel must not be nil")
            return 0
        }
        return numberOfRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = viewModel?.rows[indexPath.row] else {
            Log.shared.error("The row couldn't be dequeued")
            return UITableViewCell()
        }
        
        /// Cell for reset
        if row.color == .noColor,
            let cell = tableView.dequeueReusableCell(withIdentifier: resetCellIdentifier, for: indexPath)
                as? TrustManagementResetTableViewCell {
            cell.delegate = self
            cell.partnerNameLabel.text = row.name
            viewModel?.getImage(forRowAt: indexPath, complete: { (image) in
                DispatchQueue.main.async {
                    cell.partnerImageView.image = image
                }
            })
            return cell
        }
         
        /// Cell ´no-noColor´ context
        let identifier : String
        if UIDevice.current.orientation.isLandscape ||
            UIDevice.current.userInterfaceIdiom == .pad {
            identifier = masterAndDetailCellIdentifier
        } else {
            identifier = onlyMasterCellIdentifier
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
            as? TrustManagementTableViewCell else {
                Log.shared.error("The TrustManagementTableViewCell couldn't be dequeued")
                return UITableViewCell()
        }
        viewModel?.getImage(forRowAt: indexPath, complete: { (image) in
            DispatchQueue.main.async {
                cell.partnerImageView.image = image
            }
        })
        cell.privacyStatusImageView.image = row.privacyStatusImage
        cell.partnerNameLabel.text = row.name
        cell.privacyStatusLabel.text = row.privacyStatusName
        cell.descriptionLabel.text = row.description
        configureTrustwords(identifier, row, cell, indexPath)
        cell.delegate = self
        return cell
    }
}

/// MARK: - UIAlertControllers

extension TrustManagementViewController {
    
    /// This should only be used if the flow comes from the Compose View.
    private func presentToogleProtectionActionSheet() {
        guard let viewModel = viewModel else {
            Log.shared.errorAndCrash("View Model must not be nil")
            return
        }
        let alertController = UIAlertController.pEpAlertController(title: nil, message: nil,
                                                                   preferredStyle: .actionSheet)
        let enable = NSLocalizedString("Enable Protection", comment: "Enable Protection")
        let disable = NSLocalizedString("Disable Protection", comment: "Disable Protection")
        let toogleProtectionTitle = viewModel.pEpProtected  ? disable : enable
        let action = UIAlertAction(title: toogleProtectionTitle, style: .default) { [weak self] (action) in
            guard let me = self else {
                Log.shared.error("Lost myself")
                return
            }

            let newValue = viewModel.handleToggleProtectionPressed()
            me.optionsDelegate?.pEpProtectionDidChange(to: newValue)
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
        guard let indexPath = trustManagementTableView.indexPath(for: cell) else {
            Log.shared.error("IndexPath not found")
            return
        }
        let alertController = UIAlertController.pEpAlertController(title: nil,
                                                                   message: nil,
                                                                   preferredStyle: .actionSheet)
        guard let languages = viewModel?.handleChangeLanguagePressed(forRowAt: indexPath) else {
            Log.shared.error("Languages not found")
            return
        }
        //For every language a row in the action sheet.
        for language in languages {
            guard let languageName = NSLocale.current.localizedString(forLanguageCode: language)
                else {
                    Log.shared.debug("Language name not found")
                    break
            }
            let action = UIAlertAction(title: languageName, style: .default) { [weak self] (action) in
                guard let me = self else {
                    Log.shared.error("Lost myself")
                    return
                }
                me.viewModel?.didSelectLanguage(forRowAt: indexPath,
                                                language: language)
            }
            alertController.addAction(action)
        }
        
        //For the cancel button another action.
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            alertController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(cancelAction)

        //Ipad behavior.
        alertController.popoverPresentationController?.sourceView = cell.languageButton
        alertController.popoverPresentationController?.sourceRect = cell.languageButton.bounds
        present(alertController, animated: true, completion: nil)
    }
}

/// MARK: - Handshake ViewModel Delegate

extension TrustManagementViewController: TrustManagementViewModelDelegate {
    
    @objc public func reload() {
        UIView.setAnimationsEnabled(false)
        trustManagementTableView.reloadData()
        UIView.setAnimationsEnabled(true)
    }
}

/// MARK: - Back button

extension TrustManagementViewController {
    
    /// Helper method to create and set the back button in the navigation bar.
    private func setLeftBarButton() {
        let title = backButtonTitle ?? NSLocalizedString(" Messages", comment: "")
        let button = UIButton.backButton(with: title)
        let action = #selector(backButtonPressed)
        button.addTarget(self, action:action, for: .touchUpInside)
        let leftItem = UIBarButtonItem(customView: button)
        navigationItem.leftBarButtonItem = leftItem
        navigationController?.navigationBar.isTranslucent = false
    }

    @objc private func backButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
}

/// MARK: - Notification Center

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

/// MARK: - Set trustwords

extension TrustManagementViewController {
    
    /// Generates and sets the trustwords to the cell
    /// - Parameters:
    ///   - cell: The cell where the trustwords would be setted
    ///   - indexPath: The indexPath of the row to generate the trustwords.
    ///   - longMode: Indicates if the trustwords have to be long.
    private func setTrustwords(for cell: TrustManagementTableViewCell,
                               at indexPath: IndexPath,
                               longMode: Bool) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        
        vm.generateTrustwords(forRowAt: indexPath, long: longMode) { [weak self] trustwords in
            let oneSpace = " "
            let threeSpaces = "   "
            let spacedTrustwords = trustwords.replacingOccurrences(of: oneSpace, with: threeSpaces)
            let textToSet = longMode ? spacedTrustwords : "\(spacedTrustwords)…"
            if (cell.trustwordsLabel.text != textToSet) {
                cell.trustwordsLabel.text = textToSet
                self?.trustManagementTableView.updateSize()
            }
        }
    }
}

/// MARK: - TrustManagementTableViewCellDelegate

extension TrustManagementViewController: TrustManagementTableViewCellDelegate,
TrustManagementResetTableViewCellDelegate {
    func languageButtonPressed(on cell: TrustManagementTableViewCell) {
        showLanguagesList(for: cell)
    }
    
    func declineButtonPressed(on cell: TrustManagementTableViewCell) {
        if let indexPath = trustManagementTableView.indexPath(for: cell) {
            viewModel?.handleRejectHandshakePressed(at: indexPath)
        }
    }
    
    func confirmButtonPressed(on cell: TrustManagementTableViewCell) {
        if let indexPath = trustManagementTableView.indexPath(for: cell) {
            viewModel?.handleConfirmHandshakePressed(at: indexPath)
        }
    }
    
    func resetButtonPressed(on cell: UITableViewCell) {
        if let indexPath = trustManagementTableView.indexPath(for: cell) {
            viewModel?.handleResetPressed(forRowAt: indexPath)
        }
    }
    
    func trustwordsLabelPressed(on cell: TrustManagementTableViewCell) {
        if let indexPath = trustManagementTableView.indexPath(for: cell) {
            viewModel?.handleToggleLongTrustwords(forRowAt: indexPath)
        }
    }
}

/// MARK: - Cell configuration

extension TrustManagementViewController {
    
    /// This method configures the layout for the provided cell.
    /// We use 2 different cells: one for the split view the other for iphone portrait view.
    /// The layout is different, so different UI structures are used.
    /// 
    /// - Parameters:
    ///   - identifier: As we handle two different cells, the identifier is required in order to set the layout properly.
    ///   - row: The row to get information to configure the cell.
    ///   - cell: The cell to be configured.
    ///   - indexPath: The indexPath of the row, to get the trustwords.
    private func configureTrustwords(_ identifier: String, _ row: TrustManagementViewModel.Row, _ cell: TrustManagementTableViewCell, _ indexPath: IndexPath) {
        ///Yellow means secure but not trusted.
        ///That means that's the only case must display the trustwords
        if identifier == onlyMasterCellIdentifier {
            if row.color == .yellow {
                setTrustwords(for: cell, at: indexPath, longMode: row.longTrustwords)
                cell.trustwordsStackView.isHidden = false
                cell.trustwordsButtonsContainer.isHidden = false
            } else {
                cell.trustwordsStackView.isHidden = true
                cell.trustwordsButtonsContainer.isHidden = true
            }
        } else if identifier == masterAndDetailCellIdentifier {
            if row.color == .yellow {
                setTrustwords(for: cell, at: indexPath, longMode: row.longTrustwords)
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
}
