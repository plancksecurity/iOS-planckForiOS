//
//  ResetTrustViewController.swift
//  pEp
//
//  Created by Xavier Algarra on 20/09/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

import pEpIOSToolbox

class ResetTrustViewController: UIViewController, UISearchControllerDelegate, UISearchResultsUpdating {

    private let cellId = "ResetTrustSettingCell"
    private let model = ResetTrustViewModel()

    @IBOutlet var tableView: UITableView!

    private let searchController = UISearchController(searchResultsController: nil)

    override var collapsedBehavior: CollapsedSplitViewBehavior {
        return .needed
    }
    
    override var separatedBehavior: SeparatedSplitViewBehavior {
        return .detail
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    func setupView() {
        // set up tableview delegate and datasource
        tableView.dataSource = self
        tableView.delegate = self
        // Hide toolbar
        navigationController?.setToolbarHidden(true, animated: false)
        showNavigationBar()
        model.delegate = self
        // searchBar configuration
        configureSearchBar()
        //set the index color
        tableView.sectionIndexColor = UIColor.pEpGreen

        title = NSLocalizedString("Contacts", comment: "ResetTrustView title")
        if #available(iOS 11.0, *) {
            searchController.isActive = false
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = true
        }
    }

    /// Configure the search controller
    private func configureSearchBar() {
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.delegate = self
    }

    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else {
                return
        }
        model.setSearch(forSearchText: searchText)
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        model.removeSearch()
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension ResetTrustViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return model.numberOfSections()
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return model.titleForSections(index: section)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.numberOfRowsIn(section: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId) else {
            Log.shared.errorAndCrash(message: "cell imposible to get")
            return UITableViewCell()
        }
        cell.textLabel?.text = model.nameFor(indexPath: indexPath)
        cell.detailTextLabel?.text = model.detailFor(indexPath: indexPath)
        cell.detailTextLabel?.textColor = UIColor.lightGray
        return cell
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showAlert(indexPath: indexPath)
    }
    
    //usesAccessibilityFont
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if usesAccessibilityFont {
            return 50.0
        }
        return UITableView.automaticDimension
    }

    private func showAlert(indexPath: IndexPath) {

        let alertView = UIAlertController.pEpAlertController(preferredStyle: .actionSheet)
        let resetTrustThisIdentityAction = UIAlertAction(
            title: NSLocalizedString("Reset This Identity", comment: "alert action 1"),
            style: .destructive) { [weak self] action in
                guard let me = self else {
                    Log.shared.lostMySelf()
                    return
                }
                me.model.resetTrust(foridentityAt: indexPath, completion: {})
                // Note: UI reaction is immediate, even before the reset has been executed
                me.tableView.deselectRow(at: indexPath, animated: true)
        }
        alertView.addAction(resetTrustThisIdentityAction)

        if model.multipleIdentitiesExist(forIdentityAt: indexPath) {
            let resetTrustAllIdentityAction = UIAlertAction(
                title: NSLocalizedString("Reset Trust For All Identities", comment: "alert action 2"),
                style: .destructive) { [weak self] action in
                    guard let me = self else {
                        Log.shared.lostMySelf()
                        return
                    }
                    me.model.resetTrustAll(foridentityAt: indexPath, completion: {})
                    // Note: UI reaction is immediate, even before the reset has been executed
                    me.tableView.deselectRow(at: indexPath, animated: true)
            }
            alertView.addAction(resetTrustAllIdentityAction)
        }

        let cancelAction = UIAlertAction(
            title: NSLocalizedString("Cancel", comment: "alert action 3"),
            style: .cancel) { [weak self] action in
                guard let me = self else {
                    Log.shared.lostMySelf()
                    return
                }
                me.tableView.deselectRow(at: indexPath, animated: true)
        }
        alertView.addAction(cancelAction)

        let cell = tableView.cellForRow(at: indexPath)
        alertView.popoverPresentationController?.sourceView = cell?.contentView
        if let label = cell?.textLabel {
            let contentSize = label.intrinsicContentSize
            alertView.popoverPresentationController?.sourceRect =
                CGRect(x: label.frame.origin.x + contentSize.width + 5,
                       y: label.frame.origin.y + contentSize.height + 5,
                       width: 0,
                       height: 0)
        }

        present(alertView, animated: true, completion: nil)
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return model.indexTitles()
    }
}

extension ResetTrustViewController: ResetTrustViewModelDelegate {

    func willReceiveUpdates(viewModel: ResetTrustViewModel) {
        tableView.beginUpdates()
    }

    func allUpdatesReceived(viewModel: ResetTrustViewModel) {
        tableView.endUpdates()
    }

    func resetTrustViewModel(viewModel: ResetTrustViewModel, didInsertDataAt indexPaths: [IndexPath]) {
        tableView.insertRows(at: indexPaths, with: .automatic)
    }

    func resetTrustViewModel(viewModel: ResetTrustViewModel, didUpdateDataAt indexPaths: [IndexPath]) {
        tableView.reloadRows(at: indexPaths, with: .none)
    }

    func resetTrustViewModel(viewModel: ResetTrustViewModel, didRemoveDataAt indexPaths: [IndexPath]) {
        tableView.deleteRows(at: indexPaths, with: .automatic)
    }

    func resetTrustViewModel(viewModel: ResetTrustViewModel, didMoveData atIndexPath: IndexPath, toIndexPath: IndexPath) {
        tableView.moveRow(at: atIndexPath, to: toIndexPath)
    }

    func resetTrustViewModel(viewModel: ResetTrustViewModel, didInsertSectionAt position: Int) {
        tableView.insertSections([position], with: .automatic)
    }

    func resetTrustViewModel(viewModel: ResetTrustViewModel, didDeleteSectionAt position: Int) {
        tableView.deleteSections([position], with: .automatic)
    }

    func reloadData(viewModel: ResetTrustViewModel) {
        tableView.reloadData()
    }
}
