//
//  FolderListViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class FolderListViewController: UITableViewController {
    struct FolderListConfig {
        let account: IAccount
        let appConfig: AppConfig
    }

    /** Our vanilla table view cell */
    let standardCell = "standardCell"

    var config: FolderListConfig!

    var folderItems: [FolderModelOperation.FolderItem] = []

    struct UIState {
        var isUpdating = false
    }

    var state = UIState()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: standardCell)

        let refreshController = UIRefreshControl.init()
        refreshController.addTarget(self, action: #selector(self.refreshFoldersControl),
                                    forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl = refreshController

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateModelFromDataBase()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func updateModelFromDataBase() {
        let op = FolderModelOperation.init(
            account: config.account, coreDataUtil: config.appConfig.coreDataUtil)
        op.completionBlock = {
            self.folderItems = op.folderItems
            self.tableView.reloadData()
        }
        op.start()
    }

    func refreshFoldersControl(refreshControl: UIRefreshControl? = nil) {
        state.isUpdating = true
        updateUI()
        config.appConfig.grandOperator.fetchFolders(
            config.account.connectInfo, completionBlock: { error in
                self.state.isUpdating = false
                self.updateUI()
                self.tableView.reloadData()
        })
    }

    func updateUI() {
        if state.isUpdating {
            self.refreshControl?.beginRefreshing()
        } else {
            self.refreshControl?.endRefreshing()
        }
        UIApplication.sharedApplication().networkActivityIndicatorVisible = state.isUpdating
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(
        tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folderItems.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(
            standardCell, forIndexPath: indexPath)

        let fi = folderItems[indexPath.row]
        cell.textLabel?.text = fi.name

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Table view delegate

    override func tableView(
        tableView: UITableView,
        indentationLevelForRowAtIndexPath indexPath: NSIndexPath) -> Int {
        let fi = folderItems[indexPath.row]
        return fi.level
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}