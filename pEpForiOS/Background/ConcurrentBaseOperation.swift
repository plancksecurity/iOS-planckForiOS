//
//  ConcurrentBaseOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 30/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

/// This is the base for concurrent `NSOperation`s, that is operations that handle asynchronicity
/// themselves, and are typically not finished when `main()` ends. Instead, they spawn their own
/// threads or use other forms of asynchronicity.
public class ConcurrentBaseOperation: BaseOperation {
    /// If you need to spawn child operations (that is, subtasks that should be waited upon),
    /// schedule them on this queue.
    let backgroundQueue: OperationQueue = OperationQueue()

    var privateMOC: NSManagedObjectContext {
        return Record.Context.background
    }

    /// Schedule potentially long running tasks triggered by the client on this queue to not
    /// block the client.
    private let internalQueue = DispatchQueue(
        label: "security.pep.ConcurrentBaseOperation", qos: .utility, target: nil)

    /// State changes must be thread save. Synchronize them using this queue.
    private let stateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! +
        ".ConcurrentBaseOperation.statequeue")

    private var _state: OperationState = .ready

    // MARK: - LIFE CYCLE

    deinit {
        Log.shared.info(component: comp,
                        content: "\(#function): \(unsafeBitCast(self, to: UnsafeRawPointer.self))")
    }

    // MARK: - OPERATION

    public final override func start() {
        if isCancelled {
            markAsFinished()
            return
        }
        state = .executing

        if hasErrors() {
            cancel()
            return
        }
        Log.verbose(component: comp, content: "\(#function)")
        main()
    }

    public override func cancel() {
        super.cancel()
        reactOnCancel()
    }

    /// Use this if you didn't schedule any operations on `backgroundQueue` and want
    /// to signal the end of this operation.
    func markAsFinished() {
        if isExecuting {
            state = .finished
        }
    }

    ///If you scheduled operations on `backgroundQueue`, use this to 'wait' for them to finish and
    /// then signal `finished`. Although this method has 'wait' in the name, it does not block.
    func waitForBackgroundTasksToFinish() {
        internalQueue.async { [weak self] in
            guard let me = self else {
                return
            }
            me.backgroundQueue.waitUntilAllOperationsAreFinished()
            me.markAsFinished()
        }
    }

    func handleError(_ error: Error, message: String? = nil) {
        addError(error)
        if let theMessage = message {
            Log.shared.error(component: comp, errorString: theMessage, error: error)
        } else {
            Log.shared.error(component: comp, error: error)
        }
        cancel()
    }

    private func reactOnCancel() {
        func f() {
            backgroundQueue.cancelAllOperations()
            backgroundQueue.waitUntilAllOperationsAreFinished()
            markAsFinished()
        }
        internalQueue.async {
            f()
        }
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
        return state == .finished
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
