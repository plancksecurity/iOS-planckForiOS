//
//  CdAccount+FetchedResultsController.swift
//  MessageModel
//
//  Created by Martín Brude on 1/2/21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox

extension CdAccount {

    /// Triggers MQR update for all messages in this account
    /// This operation might be expensive, therefore, it's executed in background.
    ///
    /// This method does NOT save the context.
    /// - Parameter session: Session in which to launch the changes.
    public func triggerFetchedResultsControllerChangeForAllMessages(session : Session = Session.main) {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            session.perform {
                let predicate = NSPredicate(format: "parent.%@ = %@", CdFolder.RelationshipName.account, me)
                let moc = session.moc
                let messages: [CdMessage] = CdMessage.all(predicate: predicate, in: moc) ?? []
                messages.forEach { (message) in
                    let tmpParent = message.parent
                    message.parent = tmpParent
                }
            }
        }
    }
}
