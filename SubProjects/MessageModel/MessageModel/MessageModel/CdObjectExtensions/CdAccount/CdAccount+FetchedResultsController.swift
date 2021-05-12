//
//  CdAccount+FetchedResultsController.swift
//  MessageModel
//
//  Created by Martín Brude on 1/2/21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import Foundation
#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif
import CoreData

extension CdAccount {

    /// Triggers MQR update for all messages in this account
    /// This operation might be expensive, therefore, it's executed in background.
    ///
    /// This method does NOT save the context.
    /// - Parameter moc: The context to apply the change
    func triggerFetchedResultsControllerChangeForAllMessages(moc: NSManagedObjectContext = Stack.shared.mainContext) {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            moc.perform {
                let predicate = NSPredicate(format: "parent.%@ = %@", CdFolder.RelationshipName.account, me)
                let messages: [CdMessage] = CdMessage.all(predicate: predicate, in: moc) ?? []
                messages.forEach { (message) in
                    let tmpParent = message.parent
                    message.parent = tmpParent
                }
            }
        }
    }
}
