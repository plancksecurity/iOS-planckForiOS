//
//  CdImapFields+Extension.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 21/03/2017.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//

import CoreData

import pEpIOSToolbox

extension CdImapFields {
    public func imapFlags() -> ImapFlags {
        if managedObjectContext == nil {
            Log.shared.errorAndCrash("Our object has been deleted")
        }
        let moc: NSManagedObjectContext = managedObjectContext ?? Stack.shared.mainContext
        let newCdFlags = CdImapFlags(context: moc)
        let flags = localFlags?.imapFlags() ?? ImapFlags(cdObject: newCdFlags, context: moc)
        return flags
    }

    func updateFlags(message: Message) { //!!!: tripple check
        // local flags
        let changedLocalFlags = message.imapFlags
        if let savedFlags = localFlags {
            if savedFlags.rawFlagsAsShort() == changedLocalFlags.rawFlagsAsShort() {
                // same data, nothing to update
                return
            }
        }
        if managedObjectContext == nil {
            Log.shared.errorAndCrash("The object we are using has been deleted from it's MOC.")
        }
        let moc: NSManagedObjectContext = managedObjectContext ?? Stack.shared.mainContext

        let tmpLocalFlags = localFlags ?? CdImapFlags(context: moc)
        tmpLocalFlags.imapLocalFields = self
        tmpLocalFlags.update(rawValue16: changedLocalFlags.rawFlagsAsShort())

        localFlags = tmpLocalFlags

        //server flags
        serverFlags = serverFlags ?? CdImapFlags(context: moc)
    }
}
