//
//  MatchUidToMsnOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

import MessageModel

class MatchUidToMsnOperation: ConcurrentBaseOperation {
    let folderID: NSManagedObjectID
    let uid: UInt
    let msn: UInt

    init(
        parentName: String = #function,
        errorContainer: ServiceErrorProtocol = ErrorContainer(),
        folderID: NSManagedObjectID,
        uid: UInt, msn: UInt) {
        self.folderID = folderID
        self.uid = uid
        self.msn = msn
        super.init(parentName: parentName, errorContainer: errorContainer)
    }

    override func main() {
        if shouldRun() {
            privateMOC.perform {
                self.process(context: self.privateMOC)
            }
        }
    }

    func process(context: NSManagedObjectContext) {
        guard let cdFolder = context.object(with: folderID) as? CdFolder else {
            handleError(BackgroundError.CoreDataError.couldNotFindFolder(info: nil))//BUFF:CoreDataError.couldNotFindFolder)
            markAsFinished()
            return
        }
        guard let cdMsg = cdFolder.message(byUID: uid) else {
            handleError(BackgroundError.CoreDataError.couldNotFindMessage(info: nil))//BUFF: CoreDataError.couldNotFindMessage)
            markAsFinished()
            return
        }
        cdMsg.imapFields().messageNumber = Int32(msn)
        context.saveAndLogErrors()
        markAsFinished()
    }
}
