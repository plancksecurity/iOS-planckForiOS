//
//  KeySyncService.swift
//  MessageModel
//
//  Created by Andreas Buff on 07.06.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import PEPObjCAdapterFramework
import CoreData

/// Provides pEp Sync [en|dis]abled state and state changes.
public protocol KeySyncStateProvider: class {
    typealias NewState = Bool
    /// Closure called in case the pEp Sync [en|dis]abled state changed.
    var stateChangeHandler: ((NewState)->Void)? { get set }
    var isKeySyncEnabled: Bool { get }
}

class KeySyncService: NSObject, KeySyncServiceProtocol {
    /// The Adapter's pEp Sync service.
    private let pEpSync: PEPSync
    /// Monitors query for CdAccounts and handles pEp Sync accordingly (starts pEp Sync for new
    /// account if required).
    private let qrc: QueryResultsController<CdAccount>
    private var moc: NSManagedObjectContext
    weak private var keySyncStateProvider: KeySyncStateProvider?
    private(set) var handshakeHandler: KeySyncServiceHandshakeHandlerProtocol?
    weak private(set) var fastPollingDelegate: PollingDelegate?

    // MARK: - KeySyncServiceProtocol

    required init(keySyncServiceHandshakeHandler: KeySyncServiceHandshakeHandlerProtocol? = nil,
                  keySyncStateProvider: KeySyncStateProvider,
                  fastPollingDelegate: PollingDelegate? = nil) {
        self.handshakeHandler = keySyncServiceHandshakeHandler
        self.keySyncStateProvider = keySyncStateProvider
        self.fastPollingDelegate = fastPollingDelegate
        pEpSync = PEPSync(sendMessageDelegate: nil,
                               notifyHandshakeDelegate: nil)
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
        pEpSync.sendMessageDelegate = self
        pEpSync.notifyHandshakeDelegate = self
    }

    /// Spex:
    /// * have at least one account configured
    /// * call myself() for all accounts
    /// * in case Sync is enabled while startup the application must call start_sync(), otherwise it must not (default: enabled)
    ///
    /// - seeAlso: https://dev.pep.foundation/Engine/Sync%20from%20an%20application%20developer's%20perspective#application-startup
    func start() { //BUFF: make this service an operationBased service. We now call myself, that might become expensive (even it should not, because keys do not have to be generated).
        guard let stateProvider = keySyncStateProvider else {
            Log.shared.errorAndCrash("No keySyncStateProvider")
            return
        }
        moc.performAndWait {
            guard
                let cdAccounts = try? qrc.getResults(),
                cdAccounts.count > 0  else {
                    // Do not start KeySync if no accounts are setup.
                    // spex: "have at least one account configured"
                    return
            }
            // spex: call myself() for all accounts
            for cdAccount in cdAccounts {
                if let pEpUser = cdAccount.identity?.pEpIdentity() {
                    // I intentionally do not use guard here to stat sync any way.
                    do {
                        try PEPSession().mySelf(pEpUser)
                    } catch {
                        Log.shared.errorAndCrash(error: error)
                    }
                }
            }

            // spex:    in case Sync is enabled while startup the application must call start_sync(),
            //          otherwise it must not (default: enabled)
            guard stateProvider.isKeySyncEnabled else {
                // Do not start KeySync if the user disabled it.
                return
            }
            pEpSync.startup()
        }
    }

    func finish() {
        pEpSync.shutdown()
    }

    func stop() {
        pEpSync.shutdown()
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
