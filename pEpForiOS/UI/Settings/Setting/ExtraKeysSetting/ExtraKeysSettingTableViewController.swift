//
//  ExtraKeysSettingTableViewController.swift
//  pEp
//
//  Created by Andreas Buff on 13.08.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

class ExtraKeysSettingTableViewController: BaseTableViewController {
    static private let uiTableViewCellID = "ExtraKeysSettingFprCell"
    private var viewModel: ExtraKeysSettingViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = ExtraKeysSettingViewModel()
    }
}

// MARK: - UITableViewDataSource

extension ExtraKeysSettingTableViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.numRows ?? 0
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =
            tableView.dequeueReusableCell(withIdentifier: ExtraKeysSettingTableViewController.uiTableViewCellID,
                                          for: indexPath)
        cell.textLabel?.text = viewModel?[indexPath.row]

        return cell
    }
}


//// MARK: - UITableViewDelegate
//
//extension ExtraKeysSettingTableViewController: UITableViewDelegate {
//
//}
