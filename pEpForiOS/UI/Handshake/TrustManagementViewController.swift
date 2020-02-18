//
//  TrustManagementViewController.swift
//  pEp
//
//  Created by Martin Brude on 05/02/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

protocol PreviousViewControllerDelegate: class {
    func viewWillDismiss(viewModel : TrustManagementViewModel)
}

/// View Controller to handle the HandshakeView.
class TrustManagementViewController: BaseViewController {
        
    private let onlyMasterCellIdentifier = "TrustManagementTableViewCell_OnlyMaster"
    private let masterAndDetailCellIdentifier = "TrustManagementTableViewCell_Detailed"
    private let resetCellIdentifier = "TrustManagementTableViewResetCell"

    weak var previousViewControllerDelegate : PreviousViewControllerDelegate?
    
    @IBOutlet weak var trustManagementTableView: UITableView!
    @IBOutlet weak var optionsButton: UIBarButtonItem!
    var shouldShowOptionsButton: Bool = false

    var viewModel : TrustManagementViewModel?
    override func viewDidLoad() {
        super.viewDidLoad()

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
    }

    @IBAction private func optionsButtonPressed(_ sender: UIBarButtonItem) {
        presentToogleProtectionActionSheet()
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            viewModel?.shakeMotionDidEnd()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        trustManagementTableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let viewModel = viewModel else {
            Log.shared.error("ViewModel not found")
            return
        }
        previousViewControllerDelegate?.viewWillDismiss(viewModel: viewModel)
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
        if row.color == .noColor, let cell = tableView.dequeueReusableCell(withIdentifier: resetCellIdentifier,
                                                     for: indexPath) as? TrustManagementResetTableViewCell {
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
        let identifier = UIDevice.current.orientation.isPortrait ?
            onlyMasterCellIdentifier :  masterAndDetailCellIdentifier
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
            as? TrustManagementTableViewCell, let row = viewModel?.rows[indexPath.row] {
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
        Log.shared.error("The TrustManagementTableViewCell couldn't be dequeued or the row is nil")
        return UITableViewCell()
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
        let toogleProtectionTitle = viewModel.pEpProtected  ? enable : disable
        let action = UIAlertAction(title: toogleProtectionTitle, style: .default) {_ in
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
        guard let indexPath = trustManagementTableView.indexPath(for: cell) else {
            Log.shared.error("IndexPath not found")
            return
        }
        
        let alertController = UIAlertController.pEpAlertController(title: nil,
                                                                   message: nil,
                                                                   preferredStyle: .actionSheet)
        guard let languages = viewModel?.handleChangeLanguagePressed() else {
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
    func didToogleLongTrustwords(forRowAt indexPath: IndexPath) {
        trustManagementTableView.reloadData()
    }
    
    func didEndShakeMotion() {
        trustManagementTableView.reloadData()
    }
    
    func didResetHandshake(forRowAt indexPath: IndexPath) {
        trustManagementTableView.reloadData()
    }
    
    func didConfirmHandshake(forRowAt indexPath: IndexPath) {
        trustManagementTableView.reloadData()
    }
    
    func didRejectHandshake(forRowAt indexPath: IndexPath) {
        trustManagementTableView.reloadData()
    }
    
    func didSelectLanguage(forRowAt indexPath: IndexPath) {
        trustManagementTableView.reloadData()
    }
}

/// MARK: - Back button
extension TrustManagementViewController {
    
    /// Helper method to create and set the back button in the navigation bar.
    private func setLeftBarButton() {
        let title = NSLocalizedString(" Messages", comment: "")
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

/// MARK: - Set trustwords
extension TrustManagementViewController {
    
    /// Generates and sets the trustwords to the cell
    /// - Parameters:
    ///   - cell: The cell where the trustwords would be setted
    ///   - indexPath: The indexPath of the row to generate the trustwords.
    ///   - longMode: Indicates if the trustwords have to be long.
    private func setTrustwords(for cell: TrustManagementTableViewCell, at indexPath: IndexPath, longMode: Bool) {
        let trustwords = viewModel?.generateTrustwords(forRowAt: indexPath, long: longMode)
        let oneSpace = " "
        let threeSpaces = "   "
        if let spacedTrustwords = trustwords?.replacingOccurrences(of: oneSpace, with: threeSpaces) {
            cell.trustwordsLabel.text = longMode ? spacedTrustwords : "\(spacedTrustwords)…"
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
