//
//  ResetTrustViewController.swift
//  pEp
//
//  Created by Xavier Algarra on 20/09/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

class ResetTrustViewController: UIViewController {

    let cellId = "ResetTrustSettingCell"
    let model = ResetTrustViewModel()

    @IBOutlet var tableView: UITableView!


    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    override func viewWillAppear(_ animated: Bool) {
        model.startMonitoring()
    }

    func setupView() {
        ///set up tableview delegate and datasource
        tableView.dataSource = self
        tableView.delegate = self
        ///Hide toolbar
        navigationController?.setToolbarHidden(true, animated: false)
        model.delegate = self
    }

}

extension ResetTrustViewController: UITableViewDataSource, UITableViewDelegate {

    //    func numberOfSections(in tableView: UITableView) -> Int {
    //        return 1
    //    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.numberOfRowsPerSection(section: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId)
        cell?.textLabel?.text = model.nameFor(indexPath: indexPath)
        return cell ?? UITableViewCell()
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showAlert(indexPath: indexPath)
    }

    private func showAlert(indexPath: IndexPath) {

        let alertView = UIAlertController.pEpAlertController(preferredStyle: .actionSheet)
        let resetTrustThisIdentityAction = UIAlertAction(
            title: NSLocalizedString("Reset Trust For This Identity", comment: "alert action 1"),
            style: .destructive, handler: { [weak self] action in
                guard let me = self else {
                    Log.shared.errorAndCrash(message: "lost myself")
                    return
                }
                me.model.resetTrustFor(indexPath: indexPath)
        })
        alertView.addAction(resetTrustThisIdentityAction)

        if model.relatedIdentities(indexPath: indexPath) {
            let resetTrustAllIdentityAction = UIAlertAction(
                title: NSLocalizedString("Reset Trust For All Identities", comment: "alert action 2"),
                style: .destructive, handler: { [weak self] action in
                    guard let me = self else {
                        Log.shared.errorAndCrash(message: "lost myself")
                        return
                    }
                    me.model.resetTrustAllFor(indexPath: indexPath)
            })
            alertView.addAction(resetTrustAllIdentityAction)
        }

        let cancelAction = UIAlertAction(
            title: NSLocalizedString("Cancel", comment: "alert action 3"),
            style: .cancel)
        alertView.addAction(cancelAction)

        present(alertView, animated: true, completion: nil)
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

    func updateView() {
        tableView.reloadData()
    }


}
