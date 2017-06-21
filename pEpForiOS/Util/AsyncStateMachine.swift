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
        /** Incoming event does not match a handler */
        case invalidStateEventCombination(S, E)
    }

    private (set) public var state: S
    public var model: M

    typealias MyEventHandler = EventHandler<E, S, M>

    var handlers = [S: [E: MyEventHandler]]()

    private let managementQueue = DispatchQueue(
        label: "AsyncStateMachine.managementQueue", qos: .utility, target: nil)

    public init(state: S, model: M) {
        self.state = state
        self.model = model
    }

    public func send(event: E, onError: @escaping ErrorHandler) {
        managementQueue.async { [weak self] in
            guard let theSelf = self else {
                return
            }
            guard
                let stateDict1 = theSelf.handlers[theSelf.state],
                let handler = stateDict1[event] else {
                    onError(StateMachineError.invalidStateEventCombination(theSelf.state, event))
                    return
            }
            theSelf.model = handler(event, theSelf.state, theSelf.model)
        }
    }

    public func handle(state: S, event: E, handler: @escaping EventHandler<E, S, M>) {
        managementQueue.async { [weak self] in
            guard let theSelf = self else {
                return
            }

            var dictEvents = theSelf.handlers[state] ?? [:]
            dictEvents[event] = handler
            theSelf.handlers[state] = dictEvents
        }
    }

    public func async(block: @escaping () -> ()) {
        managementQueue.async(execute: block)
    }
}
