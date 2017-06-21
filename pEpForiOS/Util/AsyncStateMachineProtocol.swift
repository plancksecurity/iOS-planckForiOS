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
     It's expected to return a modified model M, and can then asynchronously execute
     tasks, and when finished, send another event to the state machine.
     The state machine should be captured from the surrounding, it is not delivered
     automatically to the handler.
     */
    typealias EventHandler<E, S, M> =
        (_ event: E, _ state: S, _ model: M) -> M

    typealias ErrorHandler = (_ error: Error) -> ()

    var state: S { get }
    var model: M { get set }

    /**
     - Note: If no handle exists, the transition is not valid and will throw an error.
     */
    func send(event: E, onError: @escaping ErrorHandler)

    /**
     Handle the event `event` when sent in the state `state` with `handler`.
     */
    func handle(state:S, event: E, handler: @escaping EventHandler<E, S, M>)
}
