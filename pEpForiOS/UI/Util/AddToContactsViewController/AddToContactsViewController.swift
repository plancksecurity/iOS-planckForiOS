//
//  AddToContactsViewController.swift
//  pEp
//
//  Created by Andreas Buff on 06.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import ContactsUI

#if EXT_SHARE
import PEPIOSToolboxForAppExtensions
#else
import pEpIOSToolbox
#endif

/// Represents ContactsUI for "add a contact" to the system address book
class AddToContactsViewController: UIViewController {
    static let storyboardId = "AddToContactsViewController"
    /// Known data of the contact.
    /// Currently only email is supported.
    var emailAddress: String?

    private var contactVC: CNContactViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupContactVc()
    }

    func setupContactVc() {
        guard let address = emailAddress else {
            Log.shared.errorAndCrash("No data to add?")
            dismiss(animated: false)
            return
        }
        let newContact = CNMutableContact()
        newContact.emailAddresses.append(CNLabeledValue(label: CNLabelHome,
                                                        value: address as NSString))
        contactVC = CNContactViewController(forUnknownContact: newContact)
        guard let contactVC = contactVC else {
            Log.shared.errorAndCrash("Missing contactVC")
            return
        }
        contactVC.contactStore = CNContactStore()
        contactVC.delegate = self
        contactVC.allowsActions = false
        contactVC.view.tintColor = UIColor.pEpDarkGreen

        addChild(contactVC)
        view.addSubview(contactVC.view)
        contactVC.view.fullSizeInSuperView()
    }

    @IBAction func cancelButtonPressed() {
        dismiss(animated: true)
    }
}

extension AddToContactsViewController: CNContactViewControllerDelegate {
    func contactViewController(_ viewController: CNContactViewController,
                               didCompleteWith contact: CNContact?) {
        dismiss(animated: true)
    }
}
