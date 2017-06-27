//
//  AsyncStateMachine.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 21.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

public class AsyncStateMachine<S: Hashable, E: Hashable, M>: AsyncStateMachineProtocol {
    enum StateMachineError: Error {
        /** The state/event combination is not handled */
        case unhandledStateEvent(S, E)
    }

    private (set) public var state: S
    public var model: M

    public typealias MyStateHandler = (_ state: S, _ model: M) -> M
    public typealias MyEventHandler = (_ state: S, _ model: M, _ event: E) -> (S, M)

    var transitions = Dictionary<Tuple<S, E>, S>()
    var stateEnterHandlers = Dictionary<S, MyStateHandler>()
    var eventHandlers = Dictionary<E, MyEventHandler>()

    private let managementQueue = DispatchQueue(
        label: "AsyncStateMachine.managementQueue", qos: .utility, target: nil)

    public init(state: S, model: M) {
        self.state = state
        self.model = model
    }

    public func addTransition(srcState: S, event: E, targetState: S) {
        let tuple = Tuple(values: (srcState, event))
        transitions[tuple] = targetState
    }

    public func send(event: E, onError: @escaping ErrorHandler) {
        managementQueue.async { [weak self] in
            self?.sendInternal(event: event, onError: onError)
        }
    }

    func sendInternal(event: E, onError: @escaping ErrorHandler) {
        let tuple = Tuple(values: (state, event))
        if let targetState = transitions[tuple] {
            model = handleTransition(
                targetState: targetState, model: model)
        } else {
            if let eh = eventHandlers[event] {
                (state, model) = eh(state, model, event)
                model = handleTransition(
                    targetState: state, model: model)
            } else {
                onError(StateMachineError.unhandledStateEvent(state, event))
            }
        }
    }

    func handleTransition(targetState: S, model: M) -> M {
        state = targetState
        if let handler = stateEnterHandlers[targetState] {
            return handler(targetState, model)
        } else {
            Log.shared.warn(component: #function,
                            content: "Entered state \(targetState), but no handler")
        }
        return model
    }

    public func handleEntering(state: S, handler: @escaping MyStateHandler) {
        managementQueue.async { [weak self] in
            guard let theSelf = self else {
                return
            }
            theSelf.stateEnterHandlers[state] = handler
        }
    }

    public func handle(event: E, handler: @escaping MyEventHandler) {
        managementQueue.async { [weak self] in
            guard let theSelf = self else {
                return
            }
            theSelf.eventHandlers[event] = handler
        }
    }

    public func async(block: @escaping () -> ()) {
        managementQueue.async(execute: block)
    }
}
