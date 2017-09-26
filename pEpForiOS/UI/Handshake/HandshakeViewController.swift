//
//  HandshakeViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

class HandshakeViewController: BaseTableViewController {
    var ratingReEvaluator: RatingReEvaluator?
    var backTitle: String?

    var message: Message? {
        didSet {
            partners = message?.identitiesEligibleForHandshake(session: appConfig.session) ?? []
        }
    }

    var partners = [Identity]()
    let imageProvider = IdentityImageProvider()
    let identityViewModelCache = NSCache<Identity, HandshakePartnerTableViewCellViewModel>()

    var indexPathRequestingLanguage: IndexPath?

    override func awakeFromNib() {
        tableView.estimatedRowHeight = 72.0
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    func back(sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }

    override func didReceiveMemoryWarning() {
        identityViewModelCache.removeAllObjects()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return partners.count
    }

    /**
     Returns: A cached view model for the given `partnerIdentity` or a newly created one.
     */
    func createViewModel(partnerIdentity: Identity,
                         selfIdentity: Identity) -> HandshakePartnerTableViewCellViewModel {
        if let vm = identityViewModelCache.object(forKey: partnerIdentity) {
            return vm
        } else {
            let vm = HandshakePartnerTableViewCellViewModel(
                message: message,
                ownIdentity: selfIdentity,
                partner: partnerIdentity,
                session: session,
                imageProvider: imageProvider)
            identityViewModelCache.setObject(vm, forKey: partnerIdentity)
            return vm
        }
    }

    /**
     Adjusts the background color of the given view model depending on its position in the list,
     and the color of the previous one.
     */
    func adjustBackgroundColor(viewModel: HandshakePartnerTableViewCellViewModel,
                               indexPath: IndexPath) {
        if indexPath.row == 0 {
            viewModel.backgroundColorDark = true
        } else {
            let prevRow = indexPath.row - 1
            let partnerId = partners[prevRow]
            let prevViewModel = createViewModel(partnerIdentity: partnerId,
                                                selfIdentity: viewModel.ownIdentity)
            if prevViewModel.showTrustwords {
                viewModel.backgroundColorDark = true
            } else {
                viewModel.backgroundColorDark = !prevViewModel.backgroundColorDark
            }
        }
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: "handshakePartnerCell",
            for: indexPath) as? HandshakePartnerTableViewCell {
            cell.delegate = self

            guard let m = message else {
                return cell
            }

            guard let selfId = message?.parent.account.user else {
                Log.error( component: #function,
                           errorString: "Could not deduce account from message: \(m)")
                return cell
            }

            let theId = partners[indexPath.row]
            let viewModel = createViewModel(partnerIdentity: theId, selfIdentity: selfId)
            adjustBackgroundColor(viewModel: viewModel, indexPath: indexPath)
            cell.viewModel = viewModel
            cell.indexPath = indexPath

            return cell
        }

        return UITableViewCell()
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? HandshakePartnerTableViewCell {
            cell.didChangeSelection()
            tableView.updateSize()
        }
    }
}

// MARK: - HandshakePartnerTableViewCellDelegate

extension HandshakeViewController: HandshakePartnerTableViewCellDelegate {
    func invokeTrustAction(cell: HandshakePartnerTableViewCell, indexPath: IndexPath,
                           action: () -> ()) {
        action()
        cell.updateView()
        tableView.updateSize()

        ratingReEvaluator?.reevaluateRating()

        // reload cells after that one, to ensure the alternating colors are upheld
        var paths = [IndexPath]()
        let i1 = indexPath.row + 1
        let i2 = partners.count
        if i1 < i2 {
            for i in i1..<i2 {
                paths.append(IndexPath(row: i, section: indexPath.section))
            }
        }
        tableView.reloadRows(at: paths, with: .automatic)
    }

    func resetTrust(sender: UIButton, cell: HandshakePartnerTableViewCell,
                    indexPath: IndexPath,
                    viewModel: HandshakePartnerTableViewCellViewModel?) {
        invokeTrustAction(cell: cell, indexPath: indexPath) { viewModel?.resetTrust() }
    }

    func confirmTrust(sender: UIButton, cell: HandshakePartnerTableViewCell,
                      indexPath: IndexPath,
                      viewModel: HandshakePartnerTableViewCellViewModel?) {
        invokeTrustAction(cell: cell, indexPath: indexPath) { viewModel?.confirmTrust() }
    }

    func denyTrust(sender: UIButton, cell: HandshakePartnerTableViewCell,
                   indexPath: IndexPath,
                   viewModel: HandshakePartnerTableViewCellViewModel?) {
        invokeTrustAction(cell: cell, indexPath: indexPath) { viewModel?.denyTrust() }
    }

    func pickLanguage(sender: UIView, cell: HandshakePartnerTableViewCell,
                      indexPath: IndexPath, viewModel: HandshakePartnerTableViewCellViewModel?) {
        indexPathRequestingLanguage = indexPath
        self.performSegue(withIdentifier: .showLanguagesSegue, sender: cell)
    }

    func toggleTrustwordsLength(sender: UIView, cell: HandshakePartnerTableViewCell,
                                indexPath: IndexPath,
                                viewModel: HandshakePartnerTableViewCellViewModel?) {
        viewModel?.toggleTrustwordsLength()
        cell.updateTrustwords()
        tableView.updateSize()
    }

    @IBAction func languageSelectedAction(unwindSegue: UIStoryboardSegue) {
        if let sourceVC = unwindSegue.source as? LanguageListViewController,
            let lang = sourceVC.chosenLanguage,
            let indexPath = indexPathRequestingLanguage,
            let cell = tableView.cellForRow(at: indexPath)
                as? HandshakePartnerTableViewCell {
            cell.viewModel?.trustwordsLanguage = lang.code
            cell.viewModel?.updateTrustwords(session: session)
            cell.updateTrustwords()
            tableView.updateSize()
        }
    }
}

extension HandshakeViewController: SegueHandlerType {
    enum SegueIdentifier: String {
        case showLanguagesSegue
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .showLanguagesSegue:
            let navVC = segue.destination as? UINavigationController
            if let destination = navVC?.viewControllers.first as? LanguageListViewController ??
                segue.destination as? LanguageListViewController {
                destination.appConfig = appConfig
                prepare(destination: destination)
            }
            break
        }
    }

    func prepare(destination: LanguageListViewController) {
        let theSession = session
        destination.languages = theSession.languageList()
    }
}
