//
//  autocompleteController.swift
//  pEpForiOS
//
//  Created by ana on 27/5/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class AutocompleteController: UITableView  {

    var appConfig:AppConfig?


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
        cell.text! = posibleMatchingContacts[indexPath.row]
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

    }

}
