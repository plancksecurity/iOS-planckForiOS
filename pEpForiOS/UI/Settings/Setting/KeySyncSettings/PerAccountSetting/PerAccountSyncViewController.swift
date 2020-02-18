//
//  PerAccountSyncViewController.swift
//  pEp
//
//  Created by Xavier Algarra on 07/01/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

class PerAccountSyncViewController: BaseViewController {

    let viewModel = PerAccountSyncViewModel()

    @IBOutlet weak var tableView: UITableView!
    
    override var collapsedBehavior: CollapsedBehavior {
        get {
            return .needed
        }
    }
    
    override var separatedBehavior: SeparatedBehavior{
        get {
            return .detail
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupTableView()
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        BaseTableViewController.setupCommonSettings(tableView: tableView)
    }
}

extension PerAccountSyncViewController: UITableViewDelegate {

}

extension PerAccountSyncViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AccountCell") as? PerAccountSyncAccountTableViewCell else {
            Log.shared.errorAndCrash(message: "cell not found")
            return UITableViewCell()
        }
        cell.accountTitleLabel.text = viewModel[indexPath.row]
        cell.perAccountSwitch.setOn(viewModel.syncStatus(index: indexPath.row), animated: false)
        return cell
    }

}
