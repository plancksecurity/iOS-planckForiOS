//
//  Service.swift
//  MessageModel
//
//  Created by Andreas Buff on 15.09.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

// MARK: - State

extension Service {

    enum State {
        /// The Service does nothing and is ready to do whatever work
        case ready
        /// The Service is currently doing backgrond work
        case running
        /// The Service is currently running, but will not restart  after the current task(s) are done (i.e. will end with state `stopped`).
        case finshing
        /// The Service is working on stopping all running or scheduled tasks asap.
        /// It will not restart  afterwards (i.e. will end with state `stopped`).
        case stopping
        /// The service has been stopped.
        case stopped
    }

    enum Command {
        /// No command has yet been given.
        case none
        /// Tell the service to start.
        /// The Service is responsible if and how to handle this command.
        case start
        /// Tell the service to finish. Finish means that we are not in a hurry, but finish your
        /// current tasks and do not restart again when finished.
        /// The Service is responsible if and how to handle this command.
        /// The Service is responsible to set the desired state.
        case finish
        /// Tell the service to stop. Stop means it's urgend. Cancel what you are currently doing
        /// as fast as possible and do not start again until you get a `start` command.
        /// The Service is responsible if and how to handle this command.
        /// The Service is responsible to set the desired state.
        case stop
    }
}

/// Base class for Services.
/// Override the `next()` method to start your sevice and handle states according to your needs.
///
/// - note: A `startBlock` and a `stopBlock` *MUST* be defined before calling `start()`.
///
/// - note: You MUST inherit from this when you create a Service that does work.
///         If your service does no work itself but acts as an umbrella-service (creats, holds and
///         orchextrates several sub-services), conform to ServiceProtocol instead and forward it's
///         calls to the sub-services.
class Service: ServiceProtocol {

    /// Used soley as hash.
    private let uuid = UUID().uuidString

    /// The Service's current state.
    /// For internal bookholding. It is up to the Service if and how to
    /// take it into account.
    /// - seeAlso: Service.State for details regarding the individual states
    private var _state = State.ready
    var state: State {
        get {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            return _state
        }
        set {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            _state = newValue
            Log.shared.info("%@ - state has been set to %@",
                            "\(type(of: self))", "\(_state)")
        }
    }
    /// The last command given from clients. Can be used to figure out what's to do next after a
    /// async task.  It is up to the Service if and how to take it into account.
    private(set) var lastCommand = Command.none

    let backgroundTaskManager: BackgroundTaskManagerProtocol
    let errorPropagator: ErrorPropagator

    /// The job to be done when running the Service
    var startBlock: (()->Void)?
    /// Called when the Service did it's job (startBlock done) and the client told us to `finish()`. Use for cleaning up or tasks that s
    /// have to be done before the service is killed.
    var finishBlock: (()->Void)?
    /// Called asap after the client told us to `stop()`.
    /// The implementation must take care that the Service is shut down gracefully ASAP.
    var stopBlock: (()->Void)?

    /// Instantiate Service.
    ///
    /// - Parameters:
    ///   - backgroundTaskManager:  background manager to use. Optional. If nil, the service
    ///                             quarantees correct handling of registering and graxcefully
    ///                             ending backgroundtasks to the OS. You can pass a custom one if
    ///                             you need s specilized version. E.g. to get informed when all
    ///                             backgroundtasks finished.
    ///   - startBlock: block that starts the service.
    ///                 - note: A `startBlock` MUST be defined before calling `start()`.
    ///                 - SeeAlso: Service.Command for details about the `start` command.
    ///
    ///   - finishBlock: block that finishes the service. Pass nil if you do not need to handle
    ///                  finish.
    ///                  - SeeAlso: Service.Command for details about the `finish` command.
    ///   - stopBlock: block that stops the service. Pass nil if you do not need to handle finish.
       ///                 - note: A `stopBlock` MUST be defined before calling `start()`.
       ///                - SeeAlso: Service.Command for details about the `stop` command.
    ///   - errorPropagator: error handler
    init(backgroundTaskManager: BackgroundTaskManagerProtocol? = nil,
         startBlock: (()->Void)? = nil,
         finishBlock: (()->Void)? = nil,
         stopBlock: (()->Void)? = nil,
         errorPropagator: ErrorPropagator? = nil) {
        self.startBlock = startBlock
        self.finishBlock = finishBlock
        self.stopBlock = stopBlock
        self.backgroundTaskManager = backgroundTaskManager ??  BackgroundTaskManager()
        self.errorPropagator = errorPropagator ?? ErrorPropagator()
    }

    /// This is called for *every* call from clients.
    /// You MUST also call this when changing state.
    /// All calls for action MUST be handled here.
    ///
    /// Calles `startBlock`, `finishBlock` and `stopBlock`
    ///
    /// - SeeAlso: `next(startBlock:finishBlock:stopBlock:)` for details
    func next() {
        next(startBlock: startBlock, finishBlock: finishBlock, stopBlock: stopBlock)
    }

    /// Forwards call to BackgroundTaskManager.
    /// See BackgroundTaskManager for docs.
    /// - note: You MUST call this before starting a backgound task
    func startBackgroundTask(expirationHandler handler: (()->Void)?) throws {
        try backgroundTaskManager.startBackgroundTask(for: self, expirationHandler: handler)
    }

    /// Forwards call to BackgroundTaskManager.
    /// See BackgroundTaskManager for docs.
    /// - note: You MUST call this once your backgound task finished
    func endBackgroundTask() {
        do {
            try backgroundTaskManager.endBackgroundTask(for: self)
        } catch BackgroundTaskManager.ManagingError.unknownClient {
            // We unregistered already. No problem.
            // Ignore.
        } catch {
            Log.shared.errorAndCrash(error: error)
        }
    }

    // MARK: ServiceProtocol (Public API) (can not be in extension as it has to be override-able)

    func start() {
        guard startBlock != nil, stopBlock != nil else {
            Log.shared.errorAndCrash("Invalid state")
            return
        }
        lastCommand = .start
        next()
    }

    func stop() {
        lastCommand = .stop
        next()
    }

    func finish() {
        lastCommand = .finish
        next()
    }
}

// MARK: - Private

extension Service {

    /// This is called for *every* call from clients.
    /// You MUST also call this when changing state.
    /// All calls for action MUST be handled here.
    ///
    /// - Parameters:
    ///   - startBlock: block that starts the service.
    ///                 - SeeAlso: Service.Command for details about the `start` command.
    ///                 - note: You MUST set an appropriate state (most probably `ready`) at the
    ///                         end of this block.
    ///                 - note: You most probalby want to call `next()` when this block ended
    ///                         (in the block).
    ///
    ///   - finishBlock: block that finishes the service. Pass nil if you do not need to handle
    ///                  finish.
    ///                  - SeeAlso: Service.Command for details about the `finish` command.
    ///   - stopBlock: block that stops the service. Pass nil if you do not need to handle finish.
    ///                - SeeAlso: Service.Command for details about the `stop` command.
    private func next(startBlock: (()->Void)?, finishBlock: (()->Void)?, stopBlock: (()->Void)?) {
        Log.shared.info("%@ - next called with state: %@ - lastCommand: %@",
                        "\(type(of: self))", "\(state)", "\(lastCommand)")
        switch state {
        case .ready:
            switch lastCommand {
            case .none:
                // This can happen when `next()`is called internally before the client started
                // the service. E.g. when a QueryResultsController reports changes before the client
                // started the service.
                // Do nothing before the client told us to start the service.
                break
            case .start:
                // We are ready and the client told us to start.
                state = .running
                startBlock?()
            case .finish:
                // We are not doing anything and the client told us to finish.
                // Actually there is nothing todo, but the client might want us to do something
                // special when finishing. A cleanup task or such.
                if let finishBlock = finishBlock {
                    finishBlock()
                } else {
                    endBackgroundTask()
                }
                break
            case .stop:
                // We are not doing anything and the client told us to stop.
                // There is nothing todo and the client must not want us to do something
                // special when stopping. Stop means stop asap!
                endBackgroundTask()
            }

        case .running:
            switch lastCommand {
            case .none:
                Log.shared.errorAndCrash("I do not see a valid case. The service is runnign before the client has started it.")
                break
            case .start:
                // We are running and the client told us to start.
                // Nothing to do.
                break
            case .finish:
                // We are running and the client told us to finish.
                // Nothing to do. The `finishBlock`will be called in the next round. (Might have to be changed after IMAPSyncOPs are gracefully cancelable).
//                finishBlock?()
                break
            case .stop:
                // We are running and the client told us to stop.
                stopBlock?()
                break
            }

        case .finshing:
            switch lastCommand {
            case .none:
                Log.shared.errorAndCrash("I do not see a valid case. The service is finnishing before the client has started it.")
                break
            case .start:
                // We are finshing and the client told us to start. Will start in within next
                // `next()` call.
                // Nothing to do.
                break
            case .finish:
                // We are finshing and the client told us to finish.
                // Nothing to do.
                break
            case .stop:
                // We are finshing and the client told us to stop.
                stopBlock?()
            }

        case .stopping:
            switch lastCommand {
            case .none:
                Log.shared.errorAndCrash("I do not see a valid case. The service is stopping before the client has started it.")
                break
            case .start:
                // We are stopping and the client told us to start. Will start in within next
                // `next()` call.
                // Nothing to do.
                break
            case .finish:
                // We are stopping and the client told us to finish.
                // Nothing to do.
                break
            case .stop:
                // We are stopping and the client told us to stop.
                // Nothing to do.
                break
            }

       case .stopped:
            switch lastCommand {
            case .none:
                Log.shared.errorAndCrash("I do not see a valid case. The service is stopping before the client has started it.")
                break
            case .start:
                // We are stopped and the client told us to start.
                state = .ready
                next()
                break
            case .finish:
                // We are stopped and the client told us to finish.
                // Nothing to do.
                endBackgroundTask()
                break
            case .stop:
                // We are stopped and the client told us to stop.
                // Nothing to do.
                endBackgroundTask()
                break
            }
        }
    }
}

extension Service: Equatable {
    static func == (lhs: Service, rhs: Service) -> Bool {
        return lhs === rhs
    }
}

extension Service: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}
