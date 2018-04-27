//
//  ServiceFactory.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 10.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class ServiceFactory {
    func initialSync(
        parentName: String, backgrounder: BackgroundTaskProtocol?,
        imapSyncData: ImapSyncData, smtpSendData: SmtpSendData,
        smtpSendServiceDelegate: SmtpSendServiceDelegate?,
        syncFlagsToServerServiceDelegate: SyncFlagsToServerServiceDelegate?) -> ServiceExecutionProtocol {
        let syncFoldersService = SyncFoldersFromServerService(
            parentName: parentName, backgrounder: backgrounder, imapSyncData: imapSyncData)

        let smtpService = SmtpSendService(
            parentName: parentName, backgrounder: backgrounder,
            imapSyncData: imapSyncData, smtpSendData: smtpSendData)
        smtpService.delegate = smtpSendServiceDelegate

        let fetchMessagesService = FetchMessagesService(
            parentName: parentName, backgrounder: backgrounder, imapSyncData: imapSyncData)

        let syncMessagesService = SyncExistingMessagesService(
            parentName: parentName, backgrounder: backgrounder, imapSyncData: imapSyncData)

        let uploadFlagsService = SyncFlagsToServerService(
            parentName: parentName, backgrounder: backgrounder, imapSyncData: imapSyncData,
            folderName: ImapSync.defaultImapInboxName)
        uploadFlagsService.delegate = syncFlagsToServerServiceDelegate

        let chainedService = ServiceChainExecutor()
        chainedService.add(services: [syncFoldersService, smtpService,
                                      fetchMessagesService, syncMessagesService,
                                      uploadFlagsService])

        return chainedService
    }

    func reSync(
        parentName: String, backgrounder: BackgroundTaskProtocol?,
        imapSyncData: ImapSyncData, folderName: String) -> ServiceExecutionProtocol {
        let fetchMessagesService = FetchMessagesService(
            parentName: parentName, backgrounder: backgrounder, imapSyncData: imapSyncData)

        let syncMessagesService = SyncExistingMessagesService(
            parentName: parentName, backgrounder: backgrounder, imapSyncData: imapSyncData)

        let chainedService = ServiceChainExecutor()
        chainedService.add(services: [fetchMessagesService, syncMessagesService])

        return chainedService
    }

    func syncFlagsToServer(
        parentName: String, backgrounder: BackgroundTaskProtocol?,
        imapSyncData: ImapSyncData, folderName: String,
        syncFlagsDelegate: SyncFlagsToServerServiceDelegate?) -> ServiceExecutionProtocol {
        let uploadFlagsService = SyncFlagsToServerService(
            parentName: parentName, backgrounder: backgrounder, imapSyncData: imapSyncData,
            folderName: folderName)
        uploadFlagsService.delegate = syncFlagsDelegate
        return uploadFlagsService
    }
}
