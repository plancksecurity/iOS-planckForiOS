//
//  CreateIMAPPlanckFolderOperation.swift
//  MessageModel
//
//  Created by Andreas Buff on 24.06.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

#if EXT_SHARE
import PlanckToolboxForExtensions
#else
import PlanckToolbox
#endif

/// Checks if the planck folder (used for planck Sync messages) exists and tries to create it if it
/// does not.
class CreateIMAPPlanckFolderOperation: CreateIMAPFolderOperation {

    override init(parentName: String = #function,
         context: NSManagedObjectContext? = nil,
         errorContainer: ErrorContainerProtocol = ErrorPropagator(),
         imapConnection: ImapConnectionProtocol,
         saveContextWhenDone: Bool = true,
                  folderType: FolderType = .pEpSync) {
        super.init(parentName: parentName,
                   context: context,
                   errorContainer: errorContainer,
                   imapConnection: imapConnection,
                   saveContextWhenDone: saveContextWhenDone,
                   folderType: folderType)
    }
}
