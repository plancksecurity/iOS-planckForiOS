//
//  ComposeViewController.swift
//  pEpForiOS
//
//  Created by ana on 25/5/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class ComposeViewController: UITableViewController {

    @IBOutlet weak var receiver: UITextField!
    let autocompleteTableView = UITableView(frame: CGRectMake(0,80,320,120), style: UITableViewStyle.Plain)

    var autocompleteUrls = [String]()
    var possibleMatchingContacts = [String]()
    var appConfig: AppConfig?
    let addressBook  = AddressBook.init()

    override func viewDidLoad() {
        super.viewDidLoad()
        if addressBook.authorizationStatus == .NotDetermined {
            addressBook.authorize()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func obtainMatchingContacts () {
        GCD.onMain  {
            let pepContact = self.appConfig?.model.getContactsBySnippet(self.receiver.text!)
            for contact in pepContact! {
                self.possibleMatchingContacts.append(contact.displayString())
            }
            let systemContact = self.addressBook.contactsBySnippet(self.receiver.text!)
            for contact in systemContact {
                self.possibleMatchingContacts.append(contact.displayString())
            }

        }
    }
    @IBAction func receiverChange(sender: UITextField) {
        obtainMatchingContacts()
    }
}
