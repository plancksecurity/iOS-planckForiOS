//
//  KeySyncService.swift
//  MessageModel
//
//  Created by Andreas Buff on 07.06.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

import PEPObjCAdapter
import PlanckToolbox

class KeySyncService: NSObject, KeySyncServiceProtocol {
    /// The Adapter's pEp Sync service.
    private var pEpSync: PEPSync? = nil

    /// Monitors query for CdAccounts and handles pEp Sync accordingly (starts pEp Sync for new
    /// account if required).
    private let qrc: QueryResultsController<CdAccount>
    private var moc: NSManagedObjectContext
    private let eventQueue: OperationQueue = {
        let createe = OperationQueue()
        createe.maxConcurrentOperationCount = 1
        return createe
    }()
    weak private var keySyncStateProvider: KeySyncStateProvider?
    private(set) var handshakeHandler: KeySyncServiceHandshakeHandlerProtocol?
    let passphraseProvider: PassphraseProviderProtocol
    let usePlanckFolderProvider: UsePlanckFolderProviderProtocol
    weak private(set) var fastPollingDelegate: PollingDelegate?
    let outgoingRatingService: OutgoingRatingServiceProtocol

    // MARK: - KeySyncServiceProtocol

    required init(keySyncServiceHandshakeHandler: KeySyncServiceHandshakeHandlerProtocol? = nil,
                  keySyncStateProvider: KeySyncStateProvider,
                  fastPollingDelegate: PollingDelegate? = nil,
                  passphraseProvider: PassphraseProviderProtocol,
                  usePlanckFolderProvider: UsePlanckFolderProviderProtocol,
                  outgoingRatingService: OutgoingRatingServiceProtocol) {
        self.handshakeHandler = keySyncServiceHandshakeHandler
        self.keySyncStateProvider = keySyncStateProvider
        self.fastPollingDelegate = fastPollingDelegate
        self.passphraseProvider = passphraseProvider
        self.usePlanckFolderProvider = usePlanckFolderProvider
        self.outgoingRatingService = outgoingRatingService
        let moc: NSManagedObjectContext = Stack.shared.changePropagatorContext
        self.moc = moc
        self.qrc = QueryResultsController<CdAccount>(predicate: nil,
                                                     context: moc,
                                                     sortDescriptors: [])
        do {
            try qrc.startMonitoring()
        } catch {
            Log.shared.errorAndCrash("Invalid state?")
        }
        super.init()
        qrc.delegate = self
        keySyncStateProvider.stateChangeHandler = { [weak self] enabled in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            if enabled {
                me.start()
            } else {
                me.stop()
            }
        }
    }

    /// Spex:
    /// * have at least one account configured
    /// * call myself() for all accounts
    /// * in case Sync is enabled while startup the application must call start_sync(), otherwise it must not (default: enabled)
    ///
    /// - seeAlso:
    /// https://dev.pep.foundation/Engine/Sync%20from%20an%20application%20developer’s%20perspective
    func start() {
        eventQueue.addOperation { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }

            me.moc.performAndWait {
                guard
                    let cdAccounts = try? me.qrc.getResults(),
                    cdAccounts.count > 0  else {
                    // Do not start KeySync if no accounts are setup.
                    // spex: "have at least one account configured"
                    return
                }
                let group = DispatchGroup()
                // spex: call myself() for all accounts
                for cdAccount in cdAccounts {
                    guard let identity = cdAccount.identity else {
                        Log.shared.errorAndCrash("Account without identity!")
                        return
                    }
                    let pEpUser = identity.pEpIdentity()
                    group.enter()
                    PEPSession().mySelf(pEpUser) { (error) in
                        defer { group.leave() }
                        if error.isPassphraseError {
                            Log.shared.log(error: error)
                        } else {
                            Log.shared.errorAndCrash(error: error)
                        }
                    } successCallback: { (_) in
                        PEPSession().enableSync(for: pEpUser) { (error) in
                            defer { group.leave() }
                            if error.isPassphraseError {
                                Log.shared.log(error: error)
                            } else {
                                Log.shared.errorAndCrash(error: error)
                            }
                        } successCallback: {
                            // successfully enabled. Nothing left todo.
                            group.leave()
                        }
                    }
                }
                group.notify(queue: DispatchQueue.main) {
                    let pEpSync = PEPSync(sendMessageDelegate: self, notifyHandshakeDelegate: self)
                    me.pEpSync = pEpSync
                    pEpSync.startup()
                }
            }
        }
    }

    func finish() {
        eventQueue.addOperation  { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.pEpSync?.shutdown()
            me.pEpSync = nil
        }
    }

    func stop() {
        eventQueue.cancelAllOperations()
        eventQueue.addOperation { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.pEpSync?.shutdown()
            me.pEpSync = nil
        }
    }
}

// MARK: - QueryResultsControllerDelegate

extension KeySyncService: QueryResultsControllerDelegate {

    func queryResultsControllerDidChangeSection(Info: NSFetchedResultsSectionInfo,
                                                atSectionIndex sectionIndex: Int,
                                                for type: NSFetchedResultsChangeType) {
        // We do not mess with sections
        // Nothing to do
    }

    func queryResultsControllerWillChangeResults() {
        // Nothing to do
    }

    func queryResultsControllerDidChangeObjectAt(indexPath: IndexPath?,
                                                 forChangeType changeType: NSFetchedResultsChangeType,
                                                 newIndexPath: IndexPath?) {
        switch changeType {
        case .delete:
            // Nothing to do.
            // We may want to globally disable KeySync if the deleted account was the only existing one?
            break
        case .insert:
            start()
        case .move:
            // Nothing to do
            break
        case .update:
            // Nothing to do
            break
        @unknown default:
            Log.shared.errorAndCrash("Unhandled case")
        }
    }

    func queryResultsControllerDidChangeResults() {
        // Nothing to do
    }
}
