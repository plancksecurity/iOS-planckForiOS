//
//  ErrorPropagator.swift
//  pEp
//
//  Created by Xavier Algarra on 10/11/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

public protocol ErrorPropagatorSubscriber: class {
    /**
     Should the error currently handled/displayed?
     There are situations where this leads to glitches.
     */
    var shouldHandleErrors: Bool { get set }

    func error(propagator: ErrorPropagator, error: Error)
}

public class ErrorPropagator {
    public weak var subscriber: ErrorPropagatorSubscriber?

    public func report(error: Error) {
        subscriber?.error(propagator: self, error: error)
    }
}
