//
//  MiscUtil.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

open class MiscUtil {
    open static func optionalHashValue<T: Hashable>(_ someVar: T?) -> Int {
        if let theVar = someVar {
            return theVar.hashValue
        } else {
            return 0
        }
    }

    open static func isNilOrEmptyNSArray(_ array: NSArray?) -> Bool {
        return array == nil || array?.count == 0
    }

    open static func isEmptyString(_ s: String?) -> Bool {
        if s == nil {
            return true
        }
        if s?.characters.count == 0 {
            return true
        }
        return false
    }

    /**
     Transfers all address book contacts with a valid email into the database.
     - Parameter privateContext: A private managed object context for processing in the background
     - Parameter blockFinished: An optional callback, which gets the inserted contacts as parameter.
     */
    open static func transferAddressBook(
        _ privateContext: NSManagedObjectContext,
        blockFinished: (([Contact]) -> ())? = nil) {
        privateContext.perform() {
            var insertedContacts = [Contact]()
            let model = Model.init(context: privateContext)
            let ab = AddressBook()
            let contacts = ab.allContacts()
            for c in contacts {
                insertedContacts.append(model.insertOrUpdateContact(c))
            }
            model.save()
            if let block = blockFinished {
                block(insertedContacts)
            }
        }
    }
}
