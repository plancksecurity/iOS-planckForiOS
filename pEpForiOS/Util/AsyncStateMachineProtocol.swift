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

    typealias ErrorHandler = (_ error: Error) -> ()

    /**
     This handler is called when a state is reached.
     It's expected to return a modified model M.
     */
    typealias StateEnterHandler = (_ state: S, _ model: M) -> M

    /**
     A handler like this is called when an event comes in, and there is no transition defined.
     */
    typealias EventHandler = (_ state: S, _ model: M, _ event: E) -> ()

    var state: S { get }
    var model: M { get set }

    /**
     Marks the given State -> Event as a legal combination, and sets the target state.
     */
    func addTransition(srcState: S, event: E, targetState: S)

    /**
     Sends `event` to the state machine. If the state/event combination is invalid,
     the error handler is invoked with an error.
     */
    func send(event: E, onError: @escaping ErrorHandler)

    /**
     Might throw an exception if the handlers are ambigious, e.g. there is already a
     handler for a given state.
     */
    func handleEntering(state: S, handler: @escaping StateEnterHandler) throws

    /**
     Installs a handler for an incoming event that has no defined transition.
     */
    func handle(event: E, handler: @escaping EventHandler)

    /**
     Executes a block on the management queue.
     */
    func async(block: @escaping () -> ())
}
