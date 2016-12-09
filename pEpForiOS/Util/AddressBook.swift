//
//  AddressBook.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import AddressBook

import MessageModel

public enum AddressBookStatus {
    case authorized
    case notDetermined
    case restricted
    case denied
}

/**
 Access to ABAddressBook. Uses deprecated pre-iOS-9 functionality. Can be adapted
 to the new iOS-9 API when we ditch iOS 8 support.
 */
open class AddressBook {
    open let comp = "AddressBook"
    open fileprivate(set) var authorizationStatus: AddressBookStatus = .notDetermined
    fileprivate var splitRegex: NSRegularExpression!
    fileprivate var addressBook: ABAddressBook?

    public init() {
        do {
            splitRegex = try NSRegularExpression.init(pattern: "(\\w+)", options: [])
        } catch let err as NSError {
            Log.error(component: comp, error: err)
        }
        authorizationStatus = determineStatus()
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

    func createAddressBook() {
        var err: Unmanaged<CFError>? = nil
        addressBook = ABAddressBookCreateWithOptions(nil, &err).takeRetainedValue()
    }

    func setAddressbookComponent(
        _ name: ABPropertyID, content: String?, entry: ABRecord) -> Bool {
        if let contentUn = content {
            let success = ABRecordSetValue(entry, name, contentUn as CFTypeRef!, nil)
            return success
        } else {
            return true
        }
    }

    func createMultiStringRef() -> ABMutableMultiValue {
        return ABMultiValueCreateMutable(UInt32(kABMultiStringPropertyType)).takeUnretainedValue()
    }

    /**
     For testing only.
     */
    open func addContact(_ contact: Identity) -> Bool {
        if let ab = addressBook {
            let p = NSPredicate.init(block: { (record, bindings) -> Bool in
                let contacts = self.addressBookContactToContacts(record! as ABRecord)
                for c in contacts {
                    if c.userName == contact.userName && c.address == contact.address {
                        return true
                    }
                }
                return false
            })
            let existingContacts = contactsByPredicate(p)
            if existingContacts.count > 0 {
                return true
            }

            let entry = ABPersonCreate().takeRetainedValue()

            if let name = contact.userName {
                let (first, middle, last) = splitContactNameInTuple(name)
                if !setAddressbookComponent(kABPersonFirstNameProperty, content: first, entry: entry) {
                    return false
                }
                if !setAddressbookComponent(kABPersonMiddleNameProperty, content: middle, entry: entry) {
                    return false
                }
                if !setAddressbookComponent(kABPersonLastNameProperty, content: last, entry: entry) {
                    return false
                }
            }

            let emailMultiRef = createMultiStringRef()
            if !ABMultiValueAddValueAndLabel(emailMultiRef,
                                             contact.address as CFTypeRef!, kABOtherLabel, nil) {
                return false
            }
            if !ABRecordSetValue(entry, kABPersonEmailProperty, emailMultiRef, nil) {
                return false
            }

            var error: Unmanaged<CFError>? = nil
            if ABAddressBookAddRecord(ab, entry, &error) {
                return save()
            }
        }

        return false
    }

    open func save() -> Bool {
        if let ab = addressBook {
            if ABAddressBookHasUnsavedChanges(ab) {
                var error: Unmanaged<CFError>? = nil
                let couldSaveAddressBook = ABAddressBookSave(ab, &error)
                return couldSaveAddressBook
            } else {
                return true
            }
        }
        return false
    }

    /**
     - Returns: An `Contact` for each email address of a given address book contact.
     */
    func addressBookContactToContacts(_ contact: ABRecord) -> [Identity] {
        var result: [Identity] = []
        let identifier = ABRecordGetRecordID(contact)
        var contactName: String? = nil
        if let contactNameRef = ABRecordCopyCompositeName(contact) {
            contactName = contactNameRef.takeRetainedValue() as String
        }
        let emailMultiOpt = ABRecordCopyValue(contact, kABPersonEmailProperty)?.takeRetainedValue()
        if let emailMulti = emailMultiOpt {
            if let emails: NSArray =
                ABMultiValueCopyArrayOfAllValues(emailMulti)?.takeUnretainedValue() {
                for email in emails {
                    if let emailString = email as? String {
                        result.append(Identity.create(
                            address: emailString, userName: contactName,
                            userID: String(identifier)))
                    }
                }
            }
        }
        return result
    }

    /**
     - Returns: All contacts with an email address found in the address book as `Contact`.
     If there are several emails for a contact, several contacts are returned.
     */
    func contactsByPredicate(_ predicate: NSPredicate) -> [Identity] {
        var result: [Identity] = []

        if authorizationStatus == .denied {
            return result
        }
        guard let theAddressBook = addressBook
            else {
                Log.warn(component: comp,
                         content: "Could not open address book, although authorized")
                return result
        }
        let people: NSArray = ABAddressBookCopyArrayOfAllPeople(theAddressBook).takeRetainedValue()
        let contacts = people.filtered(using: predicate)
        for c in contacts {
            let cs = addressBookContactToContacts(c as ABRecord)
            for add in cs {
                result.append(add)
            }
        }
        return result
    }

    func determineStatus() -> AddressBookStatus {
        let status = ABAddressBookGetAuthorizationStatus()
        switch status {
        case .notDetermined:
            return .notDetermined
        case .authorized:
            createAddressBook()
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        }
    }

    open func authorize(_ block: ((AddressBook) -> ())? = nil) -> AddressBookStatus {
        switch authorizationStatus {
        case .notDetermined:
            ABAddressBookRequestAccessWithCompletion(nil) { granted, err in
                if granted {
                    self.authorizationStatus = .authorized
                    self.createAddressBook()
                }
                block?(self)
            }
            return authorizationStatus
        case .restricted, .denied, .authorized:
            return authorizationStatus
        }
    }

    open func allContacts() -> [Identity] {
        return contactsByPredicate(NSPredicate.init(value: true))
    }

    static func transferAddressBook(_ addressBook: AddressBook) {
        if addressBook.authorizationStatus == .authorized {
            var insertedContacts = [Identity]()
            let ab = AddressBook()
            let contacts = ab.allContacts()
            for c in contacts {
                insertedContacts.append(c)
            }
        }
    }

    /**
     Asks for addressbook acces and tries to transfer all contacts from there.
     */
    open static func checkAndTransfer() {
        let addressBook = AddressBook.init()
        let status = addressBook.authorizationStatus
        if status == .notDetermined {
            let _ = addressBook.authorize() { ab in
                transferAddressBook(ab)
            }
        } else {
            transferAddressBook(addressBook)
        }
    }
}
