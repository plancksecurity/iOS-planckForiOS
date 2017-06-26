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
        /** The current state does not support the event */
        case invalidStateEventCombination(S, E)
    }

    private (set) public var state: S
    public var model: M

    typealias MyEventHandler = StateEnterHandler<S, M>

    var transitions = Dictionary<Tuple<S, E>, S>()
    var stateEnterHandlers = Dictionary<S, StateEnterHandler<S, M>>()

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
            guard let theSelf = self else {
                return
            }
            let tuple = Tuple(values: (theSelf.state, event))
            guard let targetState = theSelf.transitions[tuple] else {
                onError(StateMachineError.invalidStateEventCombination(theSelf.state, event))
                return
            }
            theSelf.state = targetState
            if let handler = theSelf.stateEnterHandlers[targetState] {
                theSelf.model = handler(theSelf.state, theSelf.model)
            } else {
                Log.shared.warn(component: #function,
                                content: "Entered state \(targetState), but no handler")
            }
        }
    }

    public func onEntering(state: S, handler: @escaping StateEnterHandler<S, M>) {
        managementQueue.async { [weak self] in
            guard let theSelf = self else {
                return
            }
            theSelf.stateEnterHandlers[state] = handler
        }
    }

    public func async(block: @escaping () -> ()) {
        managementQueue.async(execute: block)
    }
}
