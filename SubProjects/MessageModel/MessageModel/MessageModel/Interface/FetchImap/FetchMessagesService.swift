//
//  FetchMessagesService.swift
//  MessageModel
//
//  Created by Xavier Algarra on 14/08/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

public final class FetchMessagesService: FetchServiceBaseClass {

    override func operationToRun(errorContainer: ErrorContainerProtocol,
                                 imapConnection: ImapConnectionProtocol,
                                 folderName: String) -> FetchMessagesInImapFolderOperation {
        let fetchOperation = FetchMessagesInImapFolderOperation(errorContainer: errorContainer,
                                                                imapConnection: imapConnection,
                                                                folderName: folderName)
        return fetchOperation
    }
}
