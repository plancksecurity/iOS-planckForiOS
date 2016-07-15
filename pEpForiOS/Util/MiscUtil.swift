//
//  MiscUtil.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

public class MiscUtil {
    public static func optionalHashValue<T: Hashable>(someVar: T?) -> Int {
        if let theVar = someVar {
            return theVar.hashValue
        } else {
            return 0
        }
    }

    public static func isNilOrEmptyNSArray(array: NSArray?) -> Bool {
        return array == nil || array?.count == 0
    }

    public static func isEmptyString(s: String?) -> Bool {
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
    public static func transferAddressBook(
        privateContext: NSManagedObjectContext,
        blockFinished: (([IContact]) -> ())? = nil) {
        privateContext.performBlock() {
            var insertedContacts = [IContact]()
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