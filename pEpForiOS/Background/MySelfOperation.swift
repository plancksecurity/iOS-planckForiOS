//
//  MySelfOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 05/12/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData
import pEpUtilities
import MessageModel

/**
 Triggers myself on all identities who are own identities.
 */
open class MySelfOperation: BaseOperation {
    let backgrounder: BackgroundTaskProtocol?
    let wholeOperationTaskID: BackgroundTaskID?

    /**
     The name of the task ID for the whole process of generating mySelf for all identities owned.
     */
    public static let taskNameWhole = "MySelfOperation"

    /**
     The name of the task ID for actual invocations of mySelf.
     */
    public static let taskNameSubOperation = "MySelfOperation.Sub"

    public init(parentName: String = #function, backgrounder: BackgroundTaskProtocol? = nil) {
        self.backgrounder = backgrounder
        self.wholeOperationTaskID = backgrounder?.beginBackgroundTask(
            taskName: MySelfOperation.taskNameWhole)
        super.init(parentName: parentName)
    }

    open override func main() {
        let context = Record.Context.background
        var ids = [PEPIdentity]()

        // Which identities are owned?
        context.performAndWait {
            let pOwnIdentity = CdIdentity.PredicateFactory.isMySelf()
            guard let cdIds = CdIdentity.all(predicate: pOwnIdentity, in: context)
                as? [CdIdentity] else {
                    return
            }
            for id in cdIds {
                ids.append(PEPUtil.pEpDict(cdIdentity: id))
            }
        }

        // Invoke mySelf on all identities

        for pEpIdent in ids {
            let taskID = backgrounder?.beginBackgroundTask(
            taskName: MySelfOperation.taskNameSubOperation)
            let session = PEPSession()
            if pEpIdent.userID != CdIdentity.pEpOwnUserID {
                Logger.backendLogger.errorAndCrash(
                    "We are about to call mySelf() on a identity with userID other than pEpOwnUserID.")
            }
            do {
                try session.mySelf(pEpIdent)
            } catch let error as NSError {
                assertionFailure("\(error)")
            }
            backgrounder?.endBackgroundTask(taskID)
        }
        backgrounder?.endBackgroundTask(wholeOperationTaskID)
    }
}
