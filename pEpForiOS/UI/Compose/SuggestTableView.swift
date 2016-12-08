//
//  SuggestTableView.swift
//
//  Created by Yves Landert on 21.11.16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import Foundation
import UIKit
import Contacts

open class SuggestTableView: UITableView, UITableViewDataSource {

    var contactStore = CNContactStore()
    var contacts = [Recipient?]()
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        
        self.dataSource = self
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeueReusableCell(withIdentifier: "contactCell", for: indexPath) as! ContactCell
        
        guard let contact = contacts[indexPath.row] else { return cell }
        cell.updateCell(contact)
        
        return cell
    }
    
    public func updateContacts(_ string: String) -> Bool {
        hide()
        contacts.removeAll()
        
        let search = string.cleanAttachments
        if (search.characters.count >= 3) {
            let keys = [
                CNContactEmailAddressesKey,
                CNContactGivenNameKey,
                CNContactFamilyNameKey,
                CNContactMiddleNameKey
            ]
            let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
            do {
                try contactStore.enumerateContacts(with: request) { contact, stop in
                    if contact.emailAddresses.count > 0  {
                        var recipient: Recipient? = nil
                        if contact.givenName.contains(find: search) ||
                            contact.familyName.contains(find: search) ||
                            contact.middleName.contains(find: search) {
                            recipient = Recipient(email: contact.firstEmail, name: contact.fullname, contact: contact)
                        } else {
                            contact.emailAddresses.forEach({ (email) in
                                let mailaddress = String(email.value)
                                if mailaddress.contains(find: search) {
                                    recipient = Recipient(email: mailaddress, name: contact.fullname, contact: contact)
                                }
                            })
                        }
                        if recipient != nil {
                            self.contacts.append(recipient)
                        }
                    }
                }
            } catch {
                print(error)
            }
            
            if contacts.count > 0 {
                reloadData()
                isHidden = false
            }
        } else {
            hide()
            reloadData()
        }
        
        return !isHidden
    }
    
    public func hide() {
        isHidden = true
    }
    
    public func didSelectContact(index: IndexPath) -> CNContact?  {
        hide()
        guard let contact = contacts[index.row]?.contact else { return nil }
        return contact
    }
}
