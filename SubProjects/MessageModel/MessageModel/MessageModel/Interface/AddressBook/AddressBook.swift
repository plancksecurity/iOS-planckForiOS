//
//  AddressBook.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Contacts
import CoreData

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

public class AddressBook {
    static private var shouldStopUpdatingExistingIdentities = false

    // MARK: - Public API

    static public func contactBy(addressBookID: String) -> CNContact? {
        let store = CNContactStore()
        do {
            let contact = try store.unifiedContact(withIdentifier: addressBookID,
                                                   keysToFetch: contactThumbnailFetchRequest())
            return contact
        } catch {
            return nil
        }
    }

    /// Figures out whether or not it is we are allowed to access the systems CNContacts.
    ///
    /// - note: If you call this the first time, we are triggereing the systems "ask for contact
    ///         permissions" alert to the user.
    ///
    /// - Returns:true is the app has permissions to access the system AddressBook, false otherwize
    @discardableResult
    static public func authorizationStateOrAskForPermissions() -> Bool {
        let store = CNContactStore()
        do {
            let _ = try store.enumerateContacts(with: contactFetchRequest()) { contact, stop in
                stop.pointee = true
            }
            return true
        } catch {
            return false
        }
    }

    /// Searches Contacts whichs name or email address contains the given serach term.
    ///
    /// - note: This is a heavy opertion. Do not call from the main queue.
    ///
    /// - Parameter searchterm: term to search contacts for
    /// - Returns: matched contacts
    static public func searchContacts(searchterm: String) -> [CNContact] {
        guard authorizationStateOrAskForPermissions() else {
            // We have no permission.
            return []
        }
        let store = CNContactStore()
        let lowercasedSerach = searchterm.lowercased()
        var contacts = [CNContact]()
        do {
            try store.enumerateContacts(with: contactFetchRequest()) { contact, stop in
                if contact.givenName.lowercased().hasPrefix(lowercasedSerach) ||
                    contact.familyName.lowercased().hasPrefix(lowercasedSerach) {
                    contacts.append(contact)
                } else {
                    for email in contact.emailAddresses {
                        if email.value.hasPrefix(lowercasedSerach) ||
                            email.value.contains("." + lowercasedSerach) ||
                            email.value.contains("-" + lowercasedSerach) {
                            contacts.append(contact)
                            break
                        }
                    }
                }
            }
            return contacts
        } catch {
            Log.shared.errorAndCrash("Error seraching contacts. Fails silently")
            return []
        }
    }
}

// MARK: - AddressBook+IdentityUpdate

extension AddressBook {

    /// Updates existing Identities with data from CNContact (name & identifier)
    ///
    /// - Parameter context: MOC we are called on
    static public func updateExistingIdentities(context: NSManagedObjectContext) {
        defer {
            shouldStopUpdatingExistingIdentities = false
        }
        Log.shared.info("starting updateExistingIdentities")
        let store = CNContactStore()
        let predicate = CdIdentity.PredicateFactory.contactsIdentifierUnknown()
        var updatees: [CdIdentity]?
        context.performAndWait {
            updatees = CdIdentity.all(predicate: predicate, in: context) as? [CdIdentity]
        }
        guard let cdIidentities = updatees else {
                Log.shared.info("ending updateExistingIdentities (nothing to do)")
                // Nothing to do
                return
        }
        var uniqueIdentities = Set(cdIidentities)
        do {
            try store.enumerateContacts(with: contactFetchRequest()) { contact, stop in
                stop.pointee = shouldStopUpdatingExistingIdentities ? true : false
                if uniqueIdentities.isEmpty {
                    stop.pointee = true
                    return
                }
                let idetifier = contact.identifier
                for email in contact.emailAddresses {
                    let name = String(format: "%@ %@ %@",
                                      contact.givenName,
                                      contact.middleName,
                                      contact.familyName)
                    let value = email.value as String
                    context.performAndWait {
                        let updatees = uniqueIdentities.filter { $0.address == value }
                        for updatee in updatees {
                            updatee.userName = name
                            updatee.addressBookID = idetifier
                            uniqueIdentities.remove(updatee)
                        }
                    }
                }
            }
        } catch {
            Log.shared.info("User denied CNContact permissions.")
            // Do nothing
        }
        Log.shared.info("ending updateExistingIdentities")
    }

    static public func cancelUpdateExistingIdentities() {
        shouldStopUpdatingExistingIdentities = true
    }
}

// MARK: - Private

extension AddressBook {

    static private func contactFetchRequest() -> CNContactFetchRequest {
        return CNContactFetchRequest(keysToFetch:
            [CNContactGivenNameKey as CNKeyDescriptor,
             CNContactFamilyNameKey as CNKeyDescriptor,
             CNContactMiddleNameKey as CNKeyDescriptor,
             CNContactEmailAddressesKey as CNKeyDescriptor,
             CNContactNicknameKey as CNKeyDescriptor,
             CNContactFormatter.descriptorForRequiredKeys(for: .fullName)])
    }

    static private func contactThumbnailFetchRequest() -> [CNKeyDescriptor] {
        return [CNContactThumbnailImageDataKey as CNKeyDescriptor,
                CNContactImageDataAvailableKey as CNKeyDescriptor]
    }
}
