//
//  ServiceFactory.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 10.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

class ServiceFactory {
    func initialSync(
        parentName: String?, backgrounder: BackgroundTaskProtocol?,
        imapSyncData: ImapSyncData, smtpSendData: SmtpSendData) -> ServiceExecutionProtocol {
        let smtpService = SmtpSendService(
            parentName: #function, backgrounder: backgrounder,
            imapSyncData: imapSyncData, smtpSendData: smtpSendData)

        let fetchFoldersService = FetchFoldersService(
            parentName: #function, backgrounder: backgrounder, imapSyncData: imapSyncData)

        let fetchMessagesService = FetchMessagesService(
            parentName: #function, backgrounder: backgrounder, imapSyncData: imapSyncData)

        let syncMessagesService = SyncExistingMessagesService(
            parentName: #function, backgrounder: backgrounder, imapSyncData: imapSyncData)

        let chainedService = ServiceChainExecutor()
        chainedService.add(services: [smtpService, fetchFoldersService,
                                      fetchMessagesService, syncMessagesService])

        return chainedService
    }
}
