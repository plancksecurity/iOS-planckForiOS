//
//  MessageModelService.swift
//  MessageModel
//
//  Created by Alejandro Gelos on 01/04/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapterTypes_iOS
import PEPObjCAdapter_iOS
import pEpIOSToolbox
import pEp4iosIntern

public protocol MessageModelServiceProtocol: ServiceProtocol {

    /// Figures out the number of new (to us) messages in Inbox, taking all verified accounts
    /// into account.
    ///
    /// - Parameter completionBlock: called when the service has finished.
    ///                              Passes nil if we could not figure out whether or not
    ///                              there are new emails.
    func checkForNewMails_old(completionHandler: @escaping (_ numNewMails: Int?) -> ()) //BUFF: must change to new service
    /// Finnihses a current checkForNewMails process as soon as possible
    func cancelCheckForNewMails_old()

    /// Tries to free as much memory as possible. Call in case of low memory
    /// (applicationDidReceiveMemoryWarning() or such)
    func freeMemory()
}

public final class MessageModelService {
    private var newMailsService: FetchNumberOfNewMailsService?

    // Service

    private let backgroundTaskManager = BackgroundTaskManager()

    /// Holds all Services that:
    /// * are supposed to be started whenever the app is started or comming to foreground
    /// * are supposed to run only once
    private var onetimeServices = [ServiceProtocol]()

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
                passphraseProvider: PassphraseProviderProtocol,
                encryptionErrorDelegate: EncryptionErrorDelegate) {
        // Mega ugly, MUST go away. Fix with Stack update.
        // Touch Stack once to assure it sets up the mainContext on the main queue
        let _ = Stack.shared

        configureAdapter(withClientsPassphraseProvider: passphraseProvider)

        setupServices(errorPropagator: errorPropagator,
                      cnContactsAccessPermissionProvider: cnContactsAccessPermissionProvider,
                      keySyncServiceHandshakeHandler: keySyncServiceHandshakeHandler,
                      keySyncStateProvider: keySyncStateProvider,
                      usePEPFolderProvider: usePEPFolderProvider,
                      passphraseProvider: passphraseProvider,
                      encryptionErrorDelegate: encryptionErrorDelegate)
    }
}

// MARK: - MessageModelServiceProtocol

extension MessageModelService: MessageModelServiceProtocol {

    public func checkForNewMails_old(completionHandler: @escaping (_ numNewMails: Int?) -> ()) {
        //BUFF: tmp solution to get rid of ReplicationService. Make new service.
        newMailsService = FetchNumberOfNewMailsService()
        newMailsService?.start(completionBlock: completionHandler)
    }

    public func cancelCheckForNewMails_old() {
        newMailsService?.stop()
    }

    public func freeMemory() {
        PEPSession.cleanup()
    }
}

// MARK: - Private

extension MessageModelService {

    private func setupServices(errorPropagator: ErrorPropagator?,
                               cnContactsAccessPermissionProvider: CNContactsAccessPermissionProviderProtocol,
                               keySyncServiceHandshakeHandler: KeySyncServiceHandshakeHandlerProtocol? = nil,
                               keySyncStateProvider: KeySyncStateProvider,
                               usePEPFolderProvider: UsePEPFolderProviderProtocol,
                               passphraseProvider: PassphraseProviderProtocol,
                               encryptionErrorDelegate: EncryptionErrorDelegate) {
        //###
        // Servcies that run only once when the app starts
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            onetimeServices = [MigrateKeychainService(keychainGroupSource: "\(kTeamId).\(bundleIdentifier)",
                                                      keychainGroupTarget: "\(kTeamId).\(kSharedKeychain)")]
        } else {
            Log.shared.errorAndCrash(message: "No bundle identifier")
        }

        //###
        // Servcies that run while the app is running (Send, decrypt, replicate, ...)
        let decryptService = DecryptService(backgroundTaskManager: backgroundTaskManager,
                                            errorPropagator: errorPropagator)
        let encryptAndSendService = EncryptAndSendService(backgroundTaskManager: backgroundTaskManager,
                                                          encryptionErrorDelegate: encryptionErrorDelegate,
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
            me.onetimeServices.forEach { $0.start() }
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
