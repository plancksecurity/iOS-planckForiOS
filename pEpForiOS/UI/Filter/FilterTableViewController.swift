//
//  FilterTableViewController.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 13/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel

class FilterTableViewController: TableViewControllerBase {

    open var inFolder: Bool = false
    open var filterEnabled: Filter?
    open var filterDelegate: FilterUpdateProtocol?

    var sections = [FilterViewModel]()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton

    }

    func back(sender: UIBarButtonItem) {

        filterEnabled = Filter.unified()
        for section in sections {
            filterEnabled?.and(filter: section.getFilter())
        }
        filterDelegate?.updateFilter(filter: filterEnabled!)

       _ = self.navigationController?.popViewController(animated: true)

    }

    override func viewWillAppear(_ animated: Bool) {
        initViewModel()

    }

    func initViewModel() {

        if !inFolder {
            sections.append(FilterViewModel(type: .accouts, filter: filterEnabled))
        }
        sections.append(FilterViewModel(type: .include, filter: filterEnabled))
        sections.append(FilterViewModel(type: .other, filter: filterEnabled))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return sections[section].count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {

        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.font = UIFont(name: "Futura", size: 11)
        header.textLabel?.textColor = UIColor.lightGray

    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "filterCell", for: indexPath)
        //cell.imageView?.image = FlagImages.create(imageSize: cell.imageView?.image).flaggedImage
        let cellvm = sections[indexPath.section][indexPath.row]
        cell.textLabel?.text = cellvm.title
        cell.imageView?.image = cellvm.icon
        cell.accessoryType = (cellvm.enabled) ? .checkmark : .none
        cell.selectionStyle = .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellvm = sections[indexPath.section][indexPath.row]
        cellvm.enabled = !cellvm.enabled
        let cell = self.tableView.cellForRow(at: indexPath)
        cell?.accessoryType = (cellvm.enabled) ? .checkmark : .none
    }
}
