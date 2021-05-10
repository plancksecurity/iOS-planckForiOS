////
////  FetchOlderImapMessagesService.swift
////  pEpForiOS
////
////  Created by Andreas Buff on 18.09.17.
////  Copyright © 2017 p≡p Security S.A. All rights reserved.
////

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

public final class FetchOlderImapMessagesService: FetchServiceBaseClass {

    override func operationToRun(errorContainer: ErrorContainerProtocol,
                                 imapConnection: ImapConnectionProtocol,
                                 folderName: String) -> FetchMessagesInImapFolderOperation {
        let op = FetchOlderImapMessagesOperation(errorContainer: errorContainer,
                                                 imapConnection: imapConnection,
                                                 folderName: folderName)
        return op
    }
}
