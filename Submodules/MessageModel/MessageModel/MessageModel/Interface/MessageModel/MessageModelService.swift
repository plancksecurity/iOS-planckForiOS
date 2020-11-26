//
//  MessageModelService.swift
//  MessageModel
//
//  Created by Alejandro Gelos on 01/04/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

public protocol MessageModelServiceProtocol: ServiceProtocol {

    /// Figures out the number of new (to us) messages in Inbox, taking all verified accounts
    /// into account.
    ///
    /// - Parameter completionBlock: called when the service has finished.
    ///                              Passes nil if we could not figure out whether or not
    ///                              there are new emails.
    func checkForNewMails_old(completionHandler: @escaping (_ numNewMails: Int?) -> ()) //BUFF: must change to new service
}

public final class MessageModelService {
    private var newMailsService: FetchNumberOfNewMailsService?

    // Service

    private let backgroundTaskManager = BackgroundTaskManager()

    /// Holds all Services that:
    /// * are supposed to be started whenever the app is started or comming to foreground
    /// * are supposed to finish running tasks and not to restart when app goes to background
    private var runtimeServices = [ServiceProtocol]()

    /// Holds all Services that:
    /// * are supposed top be started when the app is about to close/go to background
    /// * do one job and finish (e.g. updateing Identities from CNContacts)
    /// Services added MUST NOT repeat but run once and stop
    private var cleanupServices = [ServiceProtocol]()

    // MARK: - Life Cycle

    /// Must be called from the main queue
    public init(errorPropagator: ErrorPropagator? = nil,
                cnContactsAccessPermissionProvider: CNContactsAccessPermissionProviderProtocol,
                keySyncServiceHandshakeHandler: KeySyncServiceHandshakeHandlerProtocol? = nil,
                keySyncStateProvider: KeySyncStateProvider,
                usePEPFolderProvider: UsePEPFolderProviderProtocol,
                passphraseProvider: PassphraseProviderProtocol) {
        // Mega ugly, MUST go away. Fix with Stack update.
        // Touch Stack once to assure it sets up the mainContext on the main queue
        let _ = Stack.shared

        configureAdapter(withClientsPassphraseProvider: passphraseProvider)

        setupServices(errorPropagator: errorPropagator,
                      cnContactsAccessPermissionProvider: cnContactsAccessPermissionProvider,
                      keySyncServiceHandshakeHandler: keySyncServiceHandshakeHandler,
                      keySyncStateProvider: keySyncStateProvider,
                      usePEPFolderProvider: usePEPFolderProvider,
                      passphraseProvider: passphraseProvider)
    }
}

// MARK: - MessageModelServiceProtocol

extension MessageModelService: MessageModelServiceProtocol {

    public func checkForNewMails_old(completionHandler: @escaping (_ numNewMails: Int?) -> ()) {
        //BUFF: tmp solution to get rid of ReplicationService. Make new service.
        newMailsService = FetchNumberOfNewMailsService()
        newMailsService?.start(completionBlock: completionHandler)
    }
}

// MARK: - Private

extension MessageModelService {

    private func setupServices(errorPropagator: ErrorPropagator?,
                               cnContactsAccessPermissionProvider: CNContactsAccessPermissionProviderProtocol,
                               keySyncServiceHandshakeHandler: KeySyncServiceHandshakeHandlerProtocol? = nil,
                               keySyncStateProvider: KeySyncStateProvider,
                               usePEPFolderProvider: UsePEPFolderProviderProtocol,
                               passphraseProvider: PassphraseProviderProtocol) {
        //###
        // Servcies that run while the app is running (Send, decrypt, replicate, ...)
        let decryptService = DecryptService(backgroundTaskManager: backgroundTaskManager,
                                            errorPropagator: errorPropagator)
        let encryptAndSendService = EncryptAndSendService(backgroundTaskManager: backgroundTaskManager,
                                                          errorPropagator: errorPropagator)
        let replicationService = ReplicationService(backgroundTaskManager: backgroundTaskManager,
                                                       errorPropagator: errorPropagator)
        let keySyncService = KeySyncService(keySyncServiceHandshakeHandler: keySyncServiceHandshakeHandler,
                                            keySyncStateProvider: keySyncStateProvider,
                                            fastPollingDelegate: replicationService,
                                            passphraseProvider: passphraseProvider,
                                            usePEPFolderProvider: usePEPFolderProvider)
        let createPEPFolderService = CreatePepIMAPFolderService(backgroundTaskManager: backgroundTaskManager,
                                                                usePEPFolderProviderProtocol: usePEPFolderProvider)
        runtimeServices = [decryptService,
                           encryptAndSendService,
                           replicationService,
                           keySyncService,
                           createPEPFolderService]
        //###
        // Services that cleanup once when the app finishes
        let updateIdentitiesAddressBookIdService =
            UpdateIdentitiesAddressBookIdService(cnContactsAccessPermissionProvider: cnContactsAccessPermissionProvider)
        let deleteOutdatedAutoconsumableMessagesService = DeleteOutdatedAutoconsumableMessagesService()
        cleanupServices = [updateIdentitiesAddressBookIdService,
                           deleteOutdatedAutoconsumableMessagesService]
    }

    private func configureAdapter(withClientsPassphraseProvider passphraseProvider: PassphraseProviderProtocol) {
        PassphraseUtil().configureAdapterWithPassphraseForNewKeys()
        PEPObjCAdapter.setPassphraseProvider(PEPPassphraseProvider(delegate: passphraseProvider))
    }
}

extension MessageModelService: ServiceProtocol {

    public func start() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            // Forward service calls
            me.runtimeServices.forEach { $0.start() }
        }
    }

    public func finish() {
        // Forward service calls
        runtimeServices.forEach { $0.finish() }
        // Run cleanup services once
        cleanupServices.forEach { $0.start() }
    }

    public func stop() {
        // Forward service calls
        runtimeServices.forEach { $0.stop() }
        // Stop means urgend.
        cleanupServices.forEach { $0.stop() }
    }
}
