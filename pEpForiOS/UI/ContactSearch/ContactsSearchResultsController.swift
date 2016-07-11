//
//  ContactsSearchResultsController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 11/07/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

/**
 Lists a bunch of contacts. Should be used as the search results controller of a
 `UISearchController`.
 */
class ContactsSearchResultsController: UITableViewController {
    var appConfig: AppConfig!
    let cellId = "ContactTableViewCell"

    /**
     The snippet to search for in the contacts
     */
    var searchSnippet: String? = nil {
        didSet {
            updateContacts()
        }
    }

    /**
     Our table model.
     */
    var contacts: [IContact] = []

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    func updateContacts() {
        if let snippet = searchSnippet {
            let privateMOC = appConfig.coreDataUtil.privateContext()
            privateMOC.performBlock(){
                let modelBackground = Model.init(context: privateMOC)
                let contacts = modelBackground.contactsBySnippet(snippet).map() {
                    ContactDAO.init(contact: $0) as IContact
                }
                GCD.onMain() {
                    self.contacts.removeAll()
                    self.contacts.appendContentsOf(contacts)
                    self.tableView.reloadData()
                }
            }
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }

    override func tableView(
        tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(
            cellId, forIndexPath: indexPath) as! ContactTableViewCell
        cell.contact = contacts[indexPath.row]
        return cell
    }
}