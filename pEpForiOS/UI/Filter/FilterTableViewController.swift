//
//  FilterTableViewController.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 13/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel
import pEpIOSToolbox

class FilterTableViewController: BaseTableViewController {

    public var filterEnabled: MessageQueryResultsFilter?
    //!!!: this should be in the VM, not the VC
    public var filterDelegate: FilterViewDelegate?

    public var viewModel : FilterViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
        self.navigationItem.rightBarButtonItem =
            UIBarButtonItem(title: NSLocalizedString("OK",  comment: "Filter accept text"),
                            style: .plain,
                            target: self,
                            action: #selector(ok(sender:)))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initViewModel()
    }

    @objc func ok(sender: UIBarButtonItem) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        filterDelegate?.filterChanged(newFilter: vm.filter)
       _ = self.navigationController?.popViewController(animated: true)
    }

    func initViewModel() {
        guard let filter = filterEnabled else {
            Log.shared.errorAndCrash("No Filter in FilterView")
            return
        }
        self.viewModel = FilterViewModel(filter: filter)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if let model = viewModel {
            return model.sectionCount
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let model = viewModel {
            return model[section].count
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let model = viewModel {
            return model[section].title
        } else {
            return ""
        }    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {

        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.font = UIFont(name: "Futura", size: 11)
        header.textLabel?.textColor = UIColor.lightGray

    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "filterCell", for: indexPath)
        if let model = viewModel {
            let cellvm = model[indexPath.section][indexPath.row]
            cell.textLabel?.text = cellvm.title
            cell.imageView?.image = cellvm.icon
            cell.tintColor = UIColor.pEpGreen
            cell.accessoryType = (cellvm.state) ? .checkmark : .none
            cell.selectionStyle = .none
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        vm.toggleEnabledState(forRowAt: indexPath)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
