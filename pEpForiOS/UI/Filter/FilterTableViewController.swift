//
//  FilterTableViewController.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 13/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel

class FilterTableViewController: BaseTableViewController {

    open var filterEnabled: MessageQueryResultsFilter?
    open var filterDelegate: FilterUpdateProtocol?

    open var viewModel : FilterViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
        self.navigationItem.rightBarButtonItem =  UIBarButtonItem(title: NSLocalizedString("OK", comment: "Filter accept text"), style: .plain, target: self, action: #selector(ok(sender:)))

    }

    override func viewWillAppear(_ animated: Bool) {
        initViewModel()
    }


    @objc func ok(sender: UIBarButtonItem) {
//        guard let model = viewModel else {
//            fatalError("no view model")
//            return
//        }
//
//        filterDelegate?.addFilter(model.getFilters())
//       _ = self.navigationController?.popViewController(animated: true)
    }


    func initViewModel() {
        //self.viewModel = FilterViewModel(inFolder: inFolder, filter: filterEnabled)
        self.viewModel = FilterViewModel(filter: filterEnabled)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if let model = viewModel {
            return model.count
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
        if let model = viewModel {
            var cellvm = model[indexPath.section][indexPath.row]
            cellvm.state = !cellvm.state
            let cell = self.tableView.cellForRow(at: indexPath)
            cell?.accessoryType = (cellvm.state) ? .checkmark : .none
        }
    }

    /*func canDisable(accountFilters: FilterSectionViewModel) -> Bool{
        return accountFilters.accountsEnabled() > 1
    }*/
}
