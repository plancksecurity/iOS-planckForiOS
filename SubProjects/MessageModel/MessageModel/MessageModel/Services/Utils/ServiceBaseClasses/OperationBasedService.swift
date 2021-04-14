//
//  OperationBasedService.swift
//  MessageModel
//
//  Created by Andreas Buff on 19.09.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.

import Foundation
import CoreData
import pEpIOSToolbox

protocol OperationBasedServiceProtocol: ServiceProtocol {
    /// NSManagedObjectContext to work on.
    var privateMoc: NSManagedObjectContext { get }

    /// You MUST override this method to to enable OperationBasedService to do it's job.
    /// - Returns: the operations that need to be done.
    func operations() -> [Operation]

    /// Reports the error to subscribers of ErrorPropagator and resets the ErrorContainer
    /// afterwards.
    func report(error: Error)

    /// Return this from `operations()` in error case instead of an emty array if you do not want
    /// to get run imediatelly again.
    /// - Parameters
    ///         error: If not nil, the this error will be reported to subscribers befor resetting the ErrorContainer and waiting.
    ///         errorWaitTime:  seconds to wait after an error occured after all operations of
    ///                         one process round ended. Defaults to
    ///                         OperationBasedService.errorWaitTimeSeconds
    /// - Returns: an operation that:
    ///                                 * Does nothing if no error has been reported
    ///                                 * Resets the error contained and waits `errorWaitTime` seconds
    func errorHandlerOp(error: Error?, errorWaitTime: Double) -> Operation
}

/// Service that is processing `Operation`s.
/// Every Service that soley processes `Operation`s MUST inherit form this class.
///
/// Use this as base class if you create a Service that processes Operations.
/// It handles the complete start/finish/stop cycle for you and takes care about registering for
/// start/end background tasks.
/// Usage:
/// * init
/// * override `operations()`
///
/// Reminder: You MUST override `operations()`.
class OperationBasedService: Service, OperationBasedServiceProtocol {
    /// see OperationBasedServiceProtocol.errorHandlerOp docs
    static private let errorWaitTimeSeconds = 10.0

    /// Queue for internal tasks that must not block backgroundQueue
    private let internalQueue: OperationQueue = {
        let createe = OperationQueue()
        createe.maxConcurrentOperationCount = 1
        createe.name = #file + " - internalQueue"
        createe.qualityOfService = QualityOfService.userInitiated
        return createe
    }()
    /// Queue to schedule the Service's work on.
    /// You MUST queue all work on this queue to make the start/finish/stop cycle work!
    let backgroundQueue: OperationQueue = {
        let createe = OperationQueue()
        createe.name = #file + " - backgroundQueue"
        createe.qualityOfService = QualityOfService.background
        return createe
    }()

    private let runOnce: Bool

    // MARK: - Life Cycle

    /// - Parameters:
    ///   - useSerialQueue: if true, operations are processed with maxConcurrentOperationCount == 1
    ///                     otherwize the OperationQueue`s default is kept.
    ///   - runOnce:    If false, the service repeats endlessly as long as `operations().count` > 0
    ///                 (in other words: as long as "there is something to do")
    ///                 If true, the service runs once for every `start()` call. This is helpful
    ///                 for services that should run once, e.g a cleanup task that should run once
    ///                 everytime the client tells it so (by calling `start()`).
    ///   - backgroundTaskManager: see Service.init for docs
    ///   - context: Context to use when toutching Core Data. Defaults to a newPrivateConcurrent MOC.
    ///   - errorPropagator: see Service.init for docs
    init(useSerialQueue: Bool = false,
         runOnce: Bool = false,
         backgroundTaskManager: BackgroundTaskManagerProtocol? = nil,
         context: NSManagedObjectContext? = nil,
         errorPropagator: ErrorContainerProtocol? = nil) {
        self.runOnce = runOnce
        self.privateMoc = context ?? Stack.shared.newPrivateConcurrentContext
        super.init(backgroundTaskManager: backgroundTaskManager,
                   startBlock: nil, // nil as we must use `self` in block, which is not possible before super.init()
            finishBlock: nil, // nil as we must use `self` in block, which is not possible before super.init()
            stopBlock: nil,
            errorPropagator: errorPropagator) // nil as we must use `self` in block, which is not possible before super.init()

        if useSerialQueue {
            backgroundQueue.maxConcurrentOperationCount = 1
        }

        // Set the blocks
        startBlock = { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            Log.shared.info("%@ - default startBlock called with state: %@)",
                            "\(type(of: self))", "\(me.state)")
            me.startNextProcessingRound()
        }

        finishBlock = { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            Log.shared.info("%@ - default finishBlock called with state: %@)",
                            "\(type(of: self))", "\(me.state)")
            me.state = .finshing
            me.waitThenStop()
        }

        stopBlock = { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            Log.shared.info("%@ - default stopBlock called with state: %@)",
                            "\(type(of: self))", "\(me.state)")
            me.state = .stopping
            me.finishAsFastAsPossible()
        }
    }

    // MARK: - OperationBasedServiceProtocol

    let privateMoc: NSManagedObjectContext

    func operations() -> [Operation] {
        fatalError("You MUST override this")
    }

    /// Waits for all operations to finish and ends background task.
    func doNotRestart() {
        internalQueue.addOperation { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            Log.shared.info("%@ - started doNotRestart", "\(type(of: me))")
            me.backgroundQueue.waitUntilAllOperationsAreFinished()
            me.state = .ready
            me.endBackgroundTask()
            Log.shared.info("%@ - ended doNotRestart", "\(type(of: me))")
        }
    }

    func waitThenStop() {
        internalQueue.addOperation { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            Log.shared.info("%@ - started internalStop", "\(type(of: me))")
            me.backgroundQueue.waitUntilAllOperationsAreFinished()
            me.state = .stopped
            me.next()
            Log.shared.info("%@ - ended internalStop", "\(type(of: me))")
        }
    }

    func report(error: Error) {
        errorPropagator.addError(error)
        errorPropagator.reset()
    }

    /// - returns:  an Operation that waits for `errorWaitTimeSeconds` and resets the error container
    ///             IF the error container has error(s).
    ///             Does nothing otherwize.
    func errorHandlerOp(error: Error? = nil,
                        errorWaitTime: Double = OperationBasedService.errorWaitTimeSeconds) -> Operation { //BUFF: This concept is not nice. We might want to modify the BaseOperation's error handling for our new Service approach. We cannot do this while the IMAP replication is not a Service yet.
        let errorContainer = errorPropagator
        let errorhandlerOP = SelfReferencingOperation { [weak self] operation in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            if let error = error {
                errorContainer.addError(error)
            }

            guard errorContainer.hasErrors else {
                // No errors, nothing todo for error handling OP (me)
                return
            }
            guard let operation = operation, !operation.isCancelled else {
                // We are gone or we got canceled ...
                // ... Do nothing
                return
            }

            let errorMsg = " - An error osccured: \(me.errorPropagator.error.debugDescription)"
            Log.shared.error("%@%@ - Sleeping for %f seconds before accepting retry.",
                            "\(type(of: self))", errorMsg, errorWaitTime)

            let startDate = Date()
            while Date().timeIntervalSince(startDate) < errorWaitTime {
                if operation.isCancelled {
                    break
                }
                sleep(1)
            }
            me.errorPropagator.reset()
            Log.shared.info("%@ - woke up", "\(type(of: me))")
        }
        return errorhandlerOP
    }
}

// MARK: - Private

extension OperationBasedService {

    private func registerBackgroundTask() {
        do {
            try startBackgroundTask { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }
                me.finishAsFastAsPossible()
            }
        } catch BackgroundTaskManager.ManagingError.backgroundTaskAlreadyRunning {
            // Intentionally ignore it. We already have a background task running.
        } catch {
            Log.shared.errorAndCrash(error: error)
        }
    }

    /// This:
    /// * creates a new opperation for every input operations that only fulfills the `dispatchGroup`.
    /// * this new operation depends on the given operration.
    ///
    /// - note: It will be quaranteed that calls to `enter()` and `leave()` are balanced after (and
    ///         ONLY after) all given operations finished.
    ///
    /// - note: We need to know when all operations finished. There are other ways to achieve this
    ///         but this solution does not limit the client at all (like not being allowed to use
    ///         completionHandler because we would potentionally override them).
    ///
    /// - Parameters:
    ///   - dispatchGroup:  group to manage. It will be quaranteed that calls to `enter()` and
    ///                     `leave()` are balanced after (and ONLY after) all given operations
    ///                     finished.
    ///   - operations: operations the `dispatchGroup` manages state for
    /// - Returns: operations to run.
    private func addCompletionOperations(handling dispatchGroup: DispatchGroup,
                                         to operations: [Operation]) -> [Operation] {
        var allOps = [Operation]()
        for op in operations {
            dispatchGroup.enter()
            let completionOP = BlockOperation() {
                dispatchGroup.leave()
            }
            completionOP.addDependency(op)
            allOps.append(op)
            allOps.append(completionOP)
        }
        return allOps
    }

    private func startNextProcessingRound() {
        let toDos = operations()
        Log.shared.info("%@ - startNextProcessingRound called with state: %@ numOperations: %d",
                        "\(type(of: self))", "\(state)", toDos.count)
        guard !toDos.isEmpty else {
                // Nothing to do. Let everyone know we are ready.
                // Do not call next(). That would result in an endless loop
                // (lasstCommand == start, state == .ready, -> nothing todo, next(), ...).
                // Wait for QRC to trigger or client to call `start()` again instead.
                state = .ready
                return
        }
        let group = DispatchGroup()
        let toDosManagedByGroup = addCompletionOperations(handling: group, to: toDos)
        group.notify(queue: DispatchQueue.global(qos: .background)) { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            Log.shared.info("%@ - allOperationFinish block called with state: %@ runOnce: %@)",
                            "\(type(of: self))", "\(me.state)", "\(me.runOnce)")
            me.state = .ready
            if !me.runOnce {
                me.next()
            } else {
                me.doNotRestart()
            }
        }

        registerBackgroundTask()
        backgroundQueue.addOperations(toDosManagedByGroup, waitUntilFinished: false)
    }

    /// Cancels all operations, waits for them to finish and ends background task.
    private func finishAsFastAsPossible() {
        Log.shared.info("%@ - finishAsFastAsPossible called", "\(type(of: self))")
        backgroundQueue.cancelAllOperations()
        waitThenStop()
    }
}
