//
//  ContactsSelectionViewModel.swift
//  pEp
//
//  Created by Adam Kowalski on 15/06/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import Contacts

final class ContactsSelectionViewModel {

    private let store = CNContactStore()

    func getContactsOnlyWithEmail() -> [CNContact] {
        let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey] as [CNKeyDescriptor]

        var contacts = [CNContact]()

        do {
            try store.enumerateContacts(with: CNContactFetchRequest(keysToFetch: keysToFetch)) { contact, _ in
                if !contact.emailAddresses.isEmpty {
                    contacts.append(contact)
                }
            }
        } catch {
            Log.shared.errorAndCrash(error: error)
        }

        return contacts
    }
}
