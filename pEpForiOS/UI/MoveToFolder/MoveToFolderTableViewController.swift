//
//  MoveToFolderTableViewController.swift
//  pEp
//
//  Created by Xavier Algarra on 15/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class MoveToFolderTableViewController: BaseTableViewController {

    var viewModel : moveToFolderViewModel?
    let storyboardId = "MoveToFolderViewController"
    private let cellId = "FolderCell"

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setup()
        //self.tableView.reloadData()
    }

    private func setup() {
        setupNavigationBar()
        setupTableView()
    }

    private func setupTableView() {
        hideSeperatorForEmptyCells()
    }

    private func hideSeperatorForEmptyCells() {
        // Add empty footer to not show empty cells (visible as dangling seperators)
        self.tableView.tableFooterView = UIView(frame: .zero)
    }

    private func setupNavigationBar() {
        title = NSLocalizedString("Move To", comment: "MoveToFolderViewController title")
        navigationItem.leftBarButtonItem = UIBarButtonItem(title:
            NSLocalizedString("Cancel",
                              comment: "MoveToFolderViewController NavigationBar canel button title"),
                                                           style:.plain,
                                                           target:self,
                                                           action:#selector(self.backButton))
    }

    // MARK: - ACTION

    @objc func backButton() {
        dismiss(animated: true)
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if let vm = viewModel {
            return vm.count
        }
        return 0
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)

        if let vm = viewModel?[indexPath.row] {
            cell.textLabel?.text = vm.title
        }
        return cell
    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
