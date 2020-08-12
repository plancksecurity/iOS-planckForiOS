//
//  ImapSyncOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 16/12/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import pEpIOSToolbox
import CoreData

class ImapSyncOperation: ConcurrentBaseOperation {
    var imapConnection: ImapConnectionProtocol
    var syncDelegate: ImapConnectionDelegate?

    init(parentName: String = #function,
         context: NSManagedObjectContext? = nil,
         errorContainer: ErrorContainerProtocol = ErrorPropagator(),
         imapConnection: ImapConnectionProtocol) {
        self.imapConnection = imapConnection
        super.init(parentName: parentName, context: context, errorContainer: errorContainer)
    }

    func checkImapSync() -> Bool {
        let authenticationCompleted = imapConnection.authenticationCompleted
        let hasErrors = imapConnection.hasError
        if hasErrors || !authenticationCompleted {
            addError(BackgroundError.ImapError.invalidConnection(info: comp))
            waitForBackgroundTasksAndFinish()
            return false
        }
        return true
    }

    private func addIMAPError(_ error: Error) {
        addError(error)
        imapConnection.hasError = true
    }

    override public func waitForBackgroundTasksAndFinish(completion: (()->())? = nil) {
        super.waitForBackgroundTasksAndFinish() { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.imapConnection.delegate = nil
            completion?()
        }
    }

    override func handle(error: Error, message: String? = nil) {
        Log.shared.error("%@", message ?? "")
        handle(error: error)
    }
}

extension ImapSyncOperation: ImapConnectionDelegateErrorHandlerProtocol {

    public func handle(error: Error) {
        Log.shared.error("ImapSyncOperation error: %@ delegate: %@",
                         "\(error)", type(of: self).debugDescription())
        addIMAPError(error)
        waitForBackgroundTasksAndFinish()
    }
}
