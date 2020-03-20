//
//  PrepareAccountOperation.swift
//  MessageModel
//
//  Created by Xavier Algarra on 20/06/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

open class PrepareAccountOperation: ImapSyncOperation {

    var accountToPrepare: VerifiableAccount?

    public override init(parentName: String = #function,
                         context: NSManagedObjectContext? = nil,
                         errorContainer: ServiceErrorProtocol = ErrorContainer(),
                         imapSyncData: ImapSyncData) {

        super.init(context: context,
                   errorContainer: errorContainer,
                   imapSyncData: imapSyncData)
    }

    override open func main() {
        process()
    }

    private func process() {

    }

    open override func cancel() {
        super.cancel()

    }

    public override func waitForBackgroundTasksToFinish() {
        super.waitForBackgroundTasksToFinish()

    }

}
