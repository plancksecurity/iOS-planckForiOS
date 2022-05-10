//
//  ErrorMenuViewController.swift
//  pEp
//
//  Created by Martín Brude on 9/5/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

class ErrorMenuViewController: UIViewController {

    static let storyboardId = "ErrorMenuViewController"

    public var viewModel: ErrorMenuViewModel?

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let thePreviousTraitCollection = previousTraitCollection else {
            // Valid case. Optional param.
            reloadTableView()
            return
        }
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            reloadTableView()
            return
        }
        if #available(iOS 13.0, *) {
            if thePreviousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) {
                reloadTableView()
                return
            }
        }
        if ((traitCollection.verticalSizeClass != thePreviousTraitCollection.verticalSizeClass)
            || (traitCollection.horizontalSizeClass != thePreviousTraitCollection.horizontalSizeClass)) {
            reloadTableView()
        }
    }
}

extension ErrorMenuViewController : UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.handleDidSelect(rowAt: indexPath)
    }
}

extension ErrorMenuViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return 0
        }

        return vm.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return UITableViewCell()
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: vm.cellIdentifier, for: indexPath) as? ErrorMenuViewCell else {
            return UITableViewCell()
        }

        cell.configure(row: vm.rows[indexPath.row])
        return cell       
    }
}

// MARK: - Private

extension ErrorMenuViewController {

    private func reloadTableView() {

    }

}
