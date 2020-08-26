//
//  ConcurrentBaseOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 30/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

///!!!: fix visibility (max internal)

import pEpIOSToolbox

/// This is the base for concurrent `NSOperation`s, that is operations that handle asynchronicity
/// themselves, and are typically not finished when `main()` ends. Instead, they spawn their own
/// threads or use other forms of asynchronicity.
open class ConcurrentBaseOperation: BaseOperation {
    /// If you need to spawn child operations (that is, subtasks that should be waited upon),
    /// schedule them on this queue.
    let backgroundQueue: OperationQueue = OperationQueue()

    public private(set) var privateMOC: NSManagedObjectContext = Stack.shared.newPrivateConcurrentContext

    /// Schedule potentially long running tasks triggered by the client on this queue to not
    /// block the client.
    private let internalQueue = DispatchQueue(
        label: "security.pep.ConcurrentBaseOperation", qos: .utility, target: nil)

    /// State changes must be thread save. Synchronize them using this queue.
    private let stateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! +
        ".ConcurrentBaseOperation.statequeue")

    private var _state: OperationState = .ready

    // MARK: - LIFE CYCLE

    public init(parentName: String = #function,
                useSerialBackgroundQueue: Bool = true,
                context: NSManagedObjectContext? = nil,
                errorContainer: ErrorContainerProtocol = ErrorPropagator()) {
        backgroundQueue.name = "\(parentName) - background queue of ConcurrentBaseOperation"
        if useSerialBackgroundQueue {
            backgroundQueue.maxConcurrentOperationCount = 1
        }
        if let paramContext = context {
            privateMOC = paramContext
        }

        super.init(parentName: parentName, errorContainer: errorContainer)
    }

    // MARK: - OPERATION

    public final override func start() {
        Log.shared.info("starting: %@", type(of: self).debugDescription())
        if isCancelled {
            markAsFinished()
            return
        }
        state = .executing

        if hasErrors {
            cancel()
            return
        }

        main()
    }

    open override func cancel() {
        Log.shared.info("cancel: %@", type(of: self).debugDescription())
        backgroundQueue.cancelAllOperations()
        super.cancel()
        waitForBackgroundTasksAndFinish()
    }

    public func markAsFinished() {
        Log.shared.info("markAsFinished: %@", type(of: self).debugDescription())
        if isExecuting {
            state = .finished
        }
    }

    /// If you scheduled operations on `backgroundQueue`, use this to 'wait' for them to finish and
    /// then signal `finished`. Although this method has 'wait' in the name, it does not block.
    public func waitForBackgroundTasksAndFinish(completion: (()->())? = nil) {
        internalQueue.async { [weak self] in
            guard let me = self else {
                return
            }
            me.backgroundQueue.waitUntilAllOperationsAreFinished()
            completion?()
            me.markAsFinished()
        }
    }

    func handleIlligalStateErrorAndFinish(component: String = #function, hint: String? = nil) {
        let error = hint ?? ""
        Log.shared.errorAndCrash(message: error)
        handle(error:BackgroundError.GeneralError.illegalState(info: component + " - " + (hint ?? "")))
    }

    public func handle(error: Error, message: String? = nil) {
        addError(error)
        if let theMessage = message {
            Log.shared.error("%@ %@", "\(error)", theMessage)
        } else {
            Log.shared.error("%@", "\(error)")
        }
        cancel()
    }
}

// MARK: - OPERATION STATE

extension ConcurrentBaseOperation {

    @objc private enum OperationState: Int {
        case ready
        case executing
        case finished
    }

    @objc private dynamic var state: OperationState {
        get {
            return stateQueue.sync {
                _state
            }
        }
        set {
            stateQueue.sync(flags: .barrier) {
                _state = newValue
            }
        }
    }

    open override var isReady: Bool {
        return state == .ready && super.isReady
    }

    public final override var isExecuting: Bool {
        return state == .executing
    }

    public final override var isFinished: Bool {
        return state == .finished ||
            (state != .executing && state != .finished && isCancelled) // Has been canceled before starting the OP.
    }

    public final override var isAsynchronous: Bool {
        return true
    }

    open override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        if ["isReady", "isFinished", "isExecuting"].contains(key) {
            return [#keyPath(state)]
        }
        return super.keyPathsForValuesAffectingValue(forKey: key)
    }
}
