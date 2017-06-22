//
//  AsyncStateMachineProtocol.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 21.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 This is a finite state machine (FSM) with an additional internal model. So every transition is
 dependent on the current state (S), the incoming Event (E), and the current model (M).
 The model is an extension to the traditional concept of an FSM.
 You can install handlers (closures) for every state/event combination. The handler then
 is responsible for checking/changing the model, and can asynchronously send further events
 the the state machine.
 See also `async` for executing blocks on the state machine management queue, if you want
 to serialize operations and don't have your own queue.
 */
public protocol AsyncStateMachineProtocol {
    /** The type for states, typically an enum. A state is a finite state machine state. */
    associatedtype S: Hashable

    /** The type for events, typically an enum */
    associatedtype E: Hashable

    /** The model type */
    associatedtype M

    /**
     This handler is called when there is an event coming in.
     It's expected to return a modified model M, and the next state.
     Both the model and the state will then be modified with those returned
     values.
     */
    typealias EventHandler<E, S, M> =
        (_ event: E, _ state: S, _ model: M) -> (S, M)

    typealias ErrorHandler = (_ error: Error) -> ()

    var state: S { get }
    var model: M { get set }

    /**
     - Note: If no handle exists, the transition is not valid and will throw an error.
     */
    func send(event: E, onError: @escaping ErrorHandler)

    /**
     Handle the event `event` when sent in the state `state` with `handler`.
     See `EventHandler` for more information.
     Might throw an exception if the handlers are ambigious, e.g. more than one
     handler for a given state/event combination.
     */
    func handle(state:S, event: E, handler: @escaping EventHandler<E, S, M>) throws

    /**
     Executes a block on the management queue.
     */
    func async(block: @escaping () -> ())
}
