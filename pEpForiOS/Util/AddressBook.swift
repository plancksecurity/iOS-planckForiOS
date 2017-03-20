//
//  AddressBook.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Contacts

import MessageModel

open class AddressBook {
    open let comp = "AddressBook"

    fileprivate var splitRegex: NSRegularExpression!

    public init() {
        do {
            splitRegex = try NSRegularExpression.init(pattern: "(\\w+)", options: [])
        } catch let err as NSError {
            Log.error(component: comp, error: err)
        }
    }

    /**
     Splits a contact's name into an array of names.
     */
    open func splitContactName(_ name: String) -> [String] {
        let matches = splitRegex.matches(in: name, options: [], range: name.wholeRange())
        let strings = matches.map { (result: NSTextCheckingResult) -> String in
            return (name as NSString).substring(with: result.range)
        }
        return strings
    }

    /**
     Splits a contact's name into address book format: (first name, middle name, last name).
     If not possible, put it all into the last name.
     */
    open func splitContactNameInTuple(_ name: String) -> (String?, String?, String?) {
        let strings = splitContactName(name)
        if strings.count == 0 {
            return (nil, nil, nil)
        } else if strings.count == 1 {
            return (strings[0], nil, nil)
        } else if strings.count == 2 {
            return (strings[0], nil, strings[1])
        } else if strings.count == 3 {
                return (strings[0], strings[1], strings[2])
        } else {
            let last = strings.count - 1
            let middle = strings[1..<last].joined(separator: " ")
            return (strings[0], middle, strings[last])
        }
    }

    func save(contact: CNContact) {
        let name = CNContactFormatter.string(from: contact, style: .fullName)
        let userID = contact.identifier
        for e in contact.emailAddresses {
            let ident = Identity.create(address: e.value as String, userID: userID)
            ident.userName = name
            ident.save()
        }
    }

    func contactFetchRequest() -> CNContactFetchRequest {
        return CNContactFetchRequest(keysToFetch:
            [CNContactGivenNameKey as CNKeyDescriptor,
             CNContactFamilyNameKey as CNKeyDescriptor,
             CNContactMiddleNameKey as CNKeyDescriptor,
             CNContactThumbnailImageDataKey as CNKeyDescriptor,
             CNContactImageDataAvailableKey as CNKeyDescriptor,
             CNContactEmailAddressesKey as CNKeyDescriptor,
             CNContactNicknameKey as CNKeyDescriptor,
             CNContactFormatter.descriptorForRequiredKeys(for: .fullName)])
    }

    func transferContacts() {
        let store = CNContactStore()
        do {
            try store.enumerateContacts(with: contactFetchRequest(), usingBlock: { contact, stop in
                self.save(contact: contact)
            })
        } catch let e as NSError {
            Log.shared.error(component: comp, error: e)
        }
    }

    /**
     Asks for addressbook access and tries to transfer all contacts from there.
     */
    open static func checkAndTransfer() {
        AddressBook().transferContacts()
    }

    open func isAuthorized() -> Bool {
        let store = CNContactStore()
        do {
            let _ = try store.enumerateContacts(with: contactFetchRequest(), usingBlock: {
                contact, stop in
                stop[0] = true
            })
            return true
        } catch let _ as NSError {
            return false
        }
    }
}
