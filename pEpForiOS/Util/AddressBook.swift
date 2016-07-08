//
//  AddressBook.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import AddressBook

public enum AddressBookStatus {
    case Authorized
    case NotDetermined
    case Restricted
    case Denied
}

/**
 With this we are compatible with our model layer, but don't have a dependency on Core Data.
 */
public struct AddressbookContact: IContact {
    public var email: String
    public var name: String?
    public var userID: String?
    public var bccMessages: NSSet = []
    public var ccMessages: NSSet = []
    public var toMessages: NSSet = []
    public var fromMessages: NSSet = []

    public init(email: String, name: String) {
        self.email = email
        self.name = name
    }
}

/**
 Access to ABAddressBook. Uses deprecated pre-iOS-9 functionality. Can be adapted
 to the new iOS-9 API when we ditch iOS 8 support.
 */
public class AddressBook {
    public let comp = "AddressBook"
    public private(set) var authorizationStatus: AddressBookStatus = .NotDetermined
    private var splitRegex: NSRegularExpression!
    private var addressBook: ABAddressBook?

    public init() {
        do {
            splitRegex = try NSRegularExpression.init(pattern: "(\\w+)", options: [])
        } catch let err as NSError {
            Log.errorComponent(comp, error: err)
        }
        authorizationStatus = determineStatus()
    }

    /**
     Splits a contact's name into an array of names.
     */
    public func splitContactName(name: String) -> [String] {
        let matches = splitRegex.matchesInString(name, options: [], range: name.wholeRange())
        let strings = matches.map { (result: NSTextCheckingResult) -> String in
            let start = name.startIndex.advancedBy(result.range.location)
            let end = start.advancedBy(result.range.length)
            let rng = start..<end
            return name.substringWithRange(rng)
        }
        return strings
    }

    /**
     Splits a contact's name into address book format: (first name, middle name, last name).
     If not possible, put it all into the last name.
     */
    public func splitContactNameInTuple(name: String) -> (String?, String?, String?) {
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
            let middle = strings[1..<last].joinWithSeparator(" ")
            return (strings[0], middle, strings[last])
        }
    }

    func createAddressBook() {
        var err: Unmanaged<CFError>? = nil
        addressBook = ABAddressBookCreateWithOptions(nil, &err).takeRetainedValue()
    }

    func setAddressbookComponent(
        name: ABPropertyID, content: String?, entry: ABRecord) -> Bool {
        if let contentUn = content {
            let success = ABRecordSetValue(entry, name, contentUn, nil)
            return success
        } else {
            return true
        }
    }

    func createMultiStringRef() -> ABMutableMultiValueRef {
        return ABMultiValueCreateMutable(UInt32(kABMultiStringPropertyType)).takeUnretainedValue()
    }

    /**
     For testing only.
     */
    public func addContact(contact: IContact) -> Bool {
        if let ab = addressBook {
            let p = NSPredicate.init(block: { (record, bindings) -> Bool in
                let contacts = self.addressBookContactToContacts(record)
                for c in contacts {
                    if c.name == contact.name && c.email == contact.email {
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

            if let name = contact.name {
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
            if !ABMultiValueAddValueAndLabel(emailMultiRef, contact.email, kABOtherLabel, nil) {
                return false
            }
            if !ABRecordSetValue(entry, kABPersonEmailProperty, emailMultiRef, nil) {
                return false
            }

            var error: Unmanaged<CFErrorRef>? = nil
            if ABAddressBookAddRecord(ab, entry, &error) {
                save()
                return true
            }
        }

        return false
    }

    public func save() -> Bool {
        if let ab = addressBook {
            if ABAddressBookHasUnsavedChanges(ab) {
                var error: Unmanaged<CFErrorRef>? = nil
                let couldSaveAddressBook = ABAddressBookSave(ab, &error)
                return couldSaveAddressBook
            } else {
                return true
            }
        }
        return false
    }

    func addressBookContactToContacts(contact: ABRecordRef) -> [IContact] {
        var result: [IContact] = []
        let contactName = ABRecordCopyCompositeName(contact).takeRetainedValue() as String
        let emailMultiOpt = ABRecordCopyValue(contact, kABPersonEmailProperty)?.takeRetainedValue()
        if let emailMulti = emailMultiOpt {
            if let emails: NSArray = ABMultiValueCopyArrayOfAllValues(emailMulti)?.takeUnretainedValue() {
                for email in emails {
                    if let emailString = email as? String {
                        result.append(AddressbookContact.init(email: emailString, name: contactName))
                    }
                }
            }
        }
        return result
    }

    func contactsByPredicate(predicate: NSPredicate) -> [IContact] {
        var result: [IContact] = []

        if authorizationStatus == .Denied {
            return result
        }
        guard let theAddressBook = addressBook
            else {
                Log.warnComponent(comp, "Could not open address book, although authorized")
                return result
        }
        let people: NSArray = ABAddressBookCopyArrayOfAllPeople(theAddressBook).takeRetainedValue()
        let contacts = people.filteredArrayUsingPredicate(predicate)
        for c in contacts {
            let cs = addressBookContactToContacts(c)
            for add in cs {
                result.append(add)
            }
        }
        return result
    }

    public func contactsBySnippet(snippet: String) -> [IContact] {
        let p = NSPredicate.init(block: { (record: ABRecordRef, bindings) in
            let contacts = self.addressBookContactToContacts(record)
            for c in contacts {
                if c.email.contains(snippet) {
                    return true
                }
                if let name = c.name {
                    return name.contains(snippet)
                }
            }
            return false
        })
        return contactsByPredicate(p)
    }

    func determineStatus() -> AddressBookStatus {
        let status = ABAddressBookGetAuthorizationStatus()
        switch status {
        case .NotDetermined:
            return .NotDetermined
        case .Authorized:
            createAddressBook()
            return .Authorized
        case .Denied:
            return .Denied
        case .Restricted:
            return .Restricted
        }
    }

    public func authorize(block: (AddressBook -> ())? = nil) -> AddressBookStatus {
        switch authorizationStatus {
        case .NotDetermined:
            ABAddressBookRequestAccessWithCompletion(nil) { (granted: Bool, err: CFError!) in
                if granted {
                    self.authorizationStatus = .Authorized
                    self.createAddressBook()
                }
                block?(self)
            }
            return authorizationStatus
        case .Restricted, .Denied, .Authorized:
            return authorizationStatus
        }
    }
}