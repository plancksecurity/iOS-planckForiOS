//
//  DefaultSendLayer.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 31/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

/**
 Invoke completion block without errors for all actions.
 */
class DefaultSendLayer: SendLayerProtocol {
    func verify(account: CdAccount, completionBlock: SendLayerCompletionBlock?) {
        completionBlock?(nil)
    }

    func send(message: CdMessage, completionBlock: SendLayerCompletionBlock?) {
        completionBlock?(nil)
    }

    func saveDraft(message: CdMessage, completionBlock: SendLayerCompletionBlock?) {
        completionBlock?(nil)
    }

    func syncFlagsToServer(folder: CdFolder, completionBlock: SendLayerCompletionBlock?) {
        completionBlock?(nil)
    }

    func create(folderType: FolderType, account: CdAccount,
                completionBlock: SendLayerCompletionBlock?) {
        completionBlock?(nil)
    }

    func delete(folder: CdFolder, completionBlock: SendLayerCompletionBlock?) {
        completionBlock?(nil)
    }

    func delete(message: CdMessage, completionBlock: SendLayerCompletionBlock?) {
        completionBlock?(nil)
    }
}
