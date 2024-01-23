//
//  CreateIMAPSuspiciousFolderOperation.swift
//  MessageModel
//
//  Created by Martin Brude on 12/1/24.
//  Copyright © 2024 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

#if EXT_SHARE
import PlanckToolboxForExtensions
#else
import PlanckToolbox
#endif

/// Checks if the planck suspicious folder exists and tries to create it if it does not.
class CreateIMAPSuspiciousFolderOperation: CreateIMAPFolderOperation {

    override init(parentName: String = #function,
         context: NSManagedObjectContext? = nil,
         errorContainer: ErrorContainerProtocol = ErrorPropagator(),
         imapConnection: ImapConnectionProtocol,
         saveContextWhenDone: Bool = true,
                  folderType: FolderType = .suspicious) {
        super.init(parentName: parentName,
                   context: context,
                   errorContainer: errorContainer,
                   imapConnection: imapConnection,
                   saveContextWhenDone: saveContextWhenDone,
                   folderType: folderType)
    }
}
