//
//  autocompleteController.swift
//  pEpForiOS
//
//  Created by ana on 27/5/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

public class StatusView {

    public var isContactsShown = false
}


class AutocompleteController: UITableViewController {

    var substringContact: String?
    var appConfig:AppConfig?
    var autocompleteContacts = [String]()
    var posibleMatchingContacts = [String]()
    var status = StatusView()
    var indexPathClicked = 0


    override func viewDidLoad() {
        super.viewDidLoad()
        posibleMatchingContacts = ["Para","Ana","Rebollo","Pin"]
        /*let systemContacts = self.addressBook.contactsBySnippet(self.receiver.text!)
        for systemContact in systemContacts {
            self.autocompleteContacts.append(systemContact.displayString())
        }*/

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! OneValueSettingCell
        if status.isContactsShown {
            switch indexPath.row {
            case 0:
                posibleMatchingContacts = ["For:","Ana","Rebollo","Pin"]
            case 1:
                posibleMatchingContacts = ["For:","Cc:","Ana","Rebollo","Pin"]
            case 2:
                posibleMatchingContacts = ["For:","Cc:","Cco:","Ana","Rebollo","Pin"]
            default:
                posibleMatchingContacts = ["For:","Cc:","Cco:","Subject:","Message"]
            }
            if (indexPath.row > indexPathClicked) {
                print("\(indexPath.row) > \(indexPathClicked)")
                cell.backgroundColor = UIColor.groupTableViewBackgroundColor()
            } else {
                cell.backgroundColor = UIColor.whiteColor()
            }
        } else {
            posibleMatchingContacts = ["For:","Cc:","Cco:","Subject:","Message"]
            cell.backgroundColor = UIColor.whiteColor()
        }
        if (indexPath.row < posibleMatchingContacts.count) {
            cell.titleName?.text = posibleMatchingContacts[indexPath.row]
            cell.fieldName?.text = posibleMatchingContacts[indexPath.row]
        }
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        if status.isContactsShown {
            status.isContactsShown = false
            tableView.reloadData()
        } else {
            status.isContactsShown = true
            indexPathClicked = indexPath.row
            tableView.reloadData()
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "contactsSegue" {
            let secondViewController = segue.destinationViewController as! ComposeWithAutocompleteViewController
        }
    }

}
