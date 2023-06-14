//
//  DecryptService.swift
//  MessageModel
//
//  Created by Andreas Buff on 19.09.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

import PlanckToolbox

class DecryptService: QueryBasedService<CdMessage> {

    weak private var auditLogginProtocol: AuditLogginProtocol?

    ///   see Service.init for docs
    required init(backgroundTaskManager: BackgroundTaskManagerProtocol? = nil,
                  errorPropagator: ErrorPropagator?,
                  auditLogginProtocol: AuditLogginProtocol? = nil) {

        self.auditLogginProtocol = auditLogginProtocol

        // Should run concurrently. serial == true as the Engine can not deal with concurrent calls
        // to the same function.
        super.init(useSerialQueue: true,
                   backgroundTaskManager: backgroundTaskManager,
                   predicate: CdMessage.PredicateFactory.needsDecrypt(),
                   cacheName: nil,
                   sortDescriptors: [NSSortDescriptor(key: "sent", ascending: true)],
                   errorPropagator: errorPropagator)
    }

    // MARK: - Overrides

    override func operations() -> [Operation] {
        var createes = [Operation]()
        privateMoc.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            let cdMessagesToDecrypt = me.results

            for cdMessageToDecrypt in cdMessagesToDecrypt {
                let decryptOP = DecryptMessageOperation(cdMessageToDecryptObjectId: cdMessageToDecrypt.objectID,
                                                        errorContainer: me.errorPropagator,
                                                        auditLogginProtocol: me.auditLogginProtocol)
                createes.append(decryptOP)
            }
        }
        return createes
    }
}
