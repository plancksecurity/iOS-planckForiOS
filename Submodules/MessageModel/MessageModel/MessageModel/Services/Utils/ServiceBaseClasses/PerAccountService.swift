//
//  PerAccountService.swift
//  MessageModel
//
//  Created by Andreas Buff on 13.10.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

import pEpIOSToolbox

protocol PerAccountServiceAbstractProtocol: ServiceProtocol {

    /// You MUST override this method and return Service[Protocol] of your need for the given account
    func service(for cdAccount: CdAccount,
                 backgroundTaskManager: BackgroundTaskManagerProtocol,
                 errorPropagator: ErrorPropagator) -> ServiceProtocol?
}
/// Base class for umbrella services that crerates a specific service for each account.
/// This base class handles the complete lifecycle and state. It monitors CoreData for existing
/// accounts and shuts down running servcies for delted accounts and creates a new service for
/// newly created accounts. All you MUST do is overriding `service(for: CdAccount)`.
///
/// Usage:
/// * init
/// * override service(for: CdAccount) -> ServiceProtocol
class PerAccountService: QueryBasedService<CdAccount>, PerAccountServiceAbstractProtocol {
    private var accounts = [CdAccount]()
    private(set) var perAccountServices = [ServiceProtocol]()

    ///   see Service.init for docs
    init(backgroundTaskManager: BackgroundTaskManagerProtocol? = nil,
         errorPropagator: ErrorPropagator?) {
        // Create QueryBasedService for all CdSAccounts
        super.init(backgroundTaskManager: backgroundTaskManager,
                   predicate: nil,
                   sortDescriptors: [],
                   errorPropagator: errorPropagator)
        resetServices()
    }

    // MARK: - Overrrides

    // MARK: Service

    override func start() {
        perAccountServices.forEach { $0.start() }
    }

    override func finish() {
        perAccountServices.forEach { $0.finish() }
    }

    override func stop() {
        perAccountServices.forEach { $0.stop() }
    }

    // MARK: QueryBasedService

    override func handleWillChangeResults() {
        // Do nothing
    }

    override func handleDidRemove(objectAt index: Int) {
        removeService(at: index)
    }

    override func handleDidUpdate(objectAt index: Int) {
        // Do nothing. I do not see a need to update the Service.
    }

    override func handleDidInsert(objectAt index: Int) {
        // Create service for newly inserted account.
        insertServiceForAccount(at: index)
    }

    override func handleDidChangeResults() {
        // Do nothing. The sub-services do the work and handle `next()` calls themself.
    }

    // MARK: - PerAccountServiceAbstractProtocol

    func service(for cdAccount: CdAccount,
                 backgroundTaskManager: BackgroundTaskManagerProtocol,
                 errorPropagator: ErrorPropagator) -> ServiceProtocol? {
        fatalError("must be overridden")
    }
}

// MARK: - Private

extension PerAccountService {

    /// Initial setup of send services
    private func resetServices() {
        stopAllServices()
        accounts = [CdAccount]()
        perAccountServices = [ServiceProtocol]()
        privateMoc.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            for i in 0..<results.count {
                let account = results[i]
                guard let service = me.service(for: account,
                                               backgroundTaskManager: backgroundTaskManager,
                                               errorPropagator: errorPropagator) else {
                    // This account does not offer a service for the clients needs. It's ok.
                    // Maybe the client is a Service that does support only a specific protocol.
                    continue
                }
                accounts.insert(account, at: i)
                perAccountServices.insert(service, at: i)
            }
        }
    }

    private func stopAllServices() {
        stop()
    }

    private func removeService(at index: Int) {
        let addressForLogging = accounts[index].identity?.address
        let removee = perAccountServices.remove(at: index)
        removee.stop()
        accounts.remove(at: index)
        Log.shared.info("%@: Removed service for account: %@ at index %d",
                        "\(self)",
            "\(addressForLogging ?? "ACCOUNT WITHOUT ADDRESS !!!")",
            index)
    }

    /// Inserts and starts a new service for an
    private func insertServiceForAccount(at index: Int) {
        let insertedCdAccount = results[index]
        guard let serviceToInsert = service(for: insertedCdAccount,
                                            backgroundTaskManager: backgroundTaskManager,
                                            errorPropagator: errorPropagator)
            else {
                // This account does not offer a service for the clients needs. It's ok.
                // Maybe the client is a Service that does support only a specific protocol.
                return

        }
        accounts.insert(insertedCdAccount, at: index)
        perAccountServices.insert(serviceToInsert, at: index)
        serviceToInsert.start()
        Log.shared.info("%@: Inserted service for account: %@ at index %d",
                        "\(self)",
            "\(insertedCdAccount.identity?.address ?? "ACCOUNT WITHOUT ADDRESS !!!")",
            index)
    }
}
