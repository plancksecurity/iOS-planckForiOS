//
//  HandshakeViewControllerV2.swift
//  pEp
//
//  Created by Martin Brude on 05/02/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

/// View Controller to handle the HandshakeView.
class HandshakeViewControllerV2: BaseViewController {
        
    private let onlyMasterCellIdentifier = "HandshakeTableViewCell_OnlyMaster"
    private let masterAndDetailCellIdentifier = "HandshakeTableViewCell_Detailed"

    @IBOutlet private weak var handshakeTableView: UITableView!
    @IBOutlet private weak var optionsButton: UIBarButtonItem!
    
    var viewModel : HandshakeViewModel?
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let viewModel = viewModel else {
            Log.shared.errorAndCrash("The viewModel must not be nil")
            return
        }
        setLeftBarButton()
        optionsButton.title = NSLocalizedString("Options", comment: "Options")
        viewModel.handshakeViewModelDelegate = self
        
        
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
        handshakeTableView.reloadData()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        handshakeTableView.estimatedRowHeight = 370
        handshakeTableView.rowHeight = UITableView.automaticDimension
    }
}

/// MARK: - UITableViewDataSource
extension HandshakeViewControllerV2 : UITableViewDataSource  {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let numberOfRows = viewModel?.rows.count else {
            Log.shared.error("The viewModel must not be nil")
            return 0
        }
        
        return numberOfRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //Cualquier plus:
        //Iphone portrait
        //Iphone landscape:
        //iPad
        
        let identifier = UIDevice.current.orientation.isPortrait ?
            onlyMasterCellIdentifier :  masterAndDetailCellIdentifier

        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
            as? HandshakeTableViewCell, let row = viewModel?.rows[indexPath.row] {
            viewModel?.getImage(forRowAt: indexPath, complete: { (image) in
                DispatchQueue.main.async {
                    cell.partnerImageView.image = image
                }
            })
            cell.privacyStatusImageView.image = row.privacyStatusImage
            cell.partnerNameLabel.text = row.name
            cell.privacyStatusLabel.text = row.privacyStatusName
            cell.descriptionLabel.text = row.description
            ///Yellow means secure but not trusted.
            ///That means that's the only case must display the trustwords
            if row.color == .yellow {
                setTrustwords(for: cell, at: indexPath, longMode: row.longTrustwords)
                cell.trustwordsStackView.isHidden = false
                cell.trustwordsButtonsContainer.isHidden = false
            } else {
                cell.trustwordsStackView.isHidden = true
                cell.trustwordsButtonsContainer.isHidden = true
            }

            cell.delegate = self
            return cell
        }
        Log.shared.error("The HandshakeTableViewCell couldn't be dequeued or the row is nil")
        return UITableViewCell()
    }
}

/// MARK: - UIAlertControllers
extension HandshakeViewControllerV2 {
    
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
    private func showLanguagesList(for cell: HandshakeTableViewCell) {
        guard let indexPath = handshakeTableView.indexPath(for: cell) else {
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
extension HandshakeViewControllerV2: HandshakeViewModelDelegate {
    func didToogleLongTrustwords(forRowAt indexPath: IndexPath) {
        handshakeTableView.reloadData()
    }
    
    func didEndShakeMotion() {
        handshakeTableView.reloadData()
    }
    
    func didResetHandshake(forRowAt indexPath: IndexPath) {
        handshakeTableView.reloadData()
    }
    
    func didConfirmHandshake(forRowAt indexPath: IndexPath) {
        handshakeTableView.reloadData()
    }
    
    func didRejectHandshake(forRowAt indexPath: IndexPath) {
        handshakeTableView.reloadData()
    }
    
    func didSelectLanguage(forRowAt indexPath: IndexPath) {
        handshakeTableView.reloadData()
    }
}

/// MARK: - Back button
extension HandshakeViewControllerV2 {
    
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
extension HandshakeViewControllerV2 {
    
    /// Generates and sets the trustwords to the cell
    /// - Parameters:
    ///   - cell: The cell where the trustwords would be setted
    ///   - indexPath: The indexPath of the row to generate the trustwords.
    ///   - longMode: Indicates if the trustwords have to be long.
    private func setTrustwords(for cell: HandshakeTableViewCell, at indexPath: IndexPath, longMode: Bool) {
        let trustwords = viewModel?.generateTrustwords(forRowAt: indexPath, long: longMode)
        let oneSpace = " "
        let threeSpaces = "   "
        if let spacedTrustwords = trustwords?.replacingOccurrences(of: oneSpace, with: threeSpaces) {
            cell.trustwordsLabel.text = longMode ? spacedTrustwords : "\(spacedTrustwords)…"
        }
    }
}

/// MARK: - HandshakeTableViewCellDelegate
extension HandshakeViewControllerV2: HandshakeTableViewCellDelegate {
    func languageButtonPressed(on cell: HandshakeTableViewCell) {
        showLanguagesList(for: cell)
    }
    
    func declineButtonPressed(on cell: HandshakeTableViewCell) {
        if let indexPath = handshakeTableView.indexPath(for: cell) {
            viewModel?.handleRejectHandshakePressed(at: indexPath)
        }
    }
    
    func confirmButtonPressed(on cell: HandshakeTableViewCell) {
        if let indexPath = handshakeTableView.indexPath(for: cell) {
            viewModel?.handleConfirmHandshakePressed(at: indexPath)
        }
    }
    
    func resetButtonPressed(on cell: HandshakeTableViewCell) {
        if let indexPath = handshakeTableView.indexPath(for: cell) {
            viewModel?.handleResetPressed(forRowAt: indexPath)
        }
    }
    
    func trustwordsLabelPressed(on cell: HandshakeTableViewCell) {
        if let indexPath = handshakeTableView.indexPath(for: cell) {
            viewModel?.handleToggleLongTrustwords(forRowAt: indexPath)
        }
    }
}
