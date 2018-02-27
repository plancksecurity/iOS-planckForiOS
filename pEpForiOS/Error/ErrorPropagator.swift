//
//  ErrorPropagator.swift
//  pEp
//
//  Created by Xavier Algarra on 10/11/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

public protocol ErrorPropagatorSubscriber: class {
    func error(propagator: ErrorPropagator, error:Error)
}

public class ErrorPropagator {
    public weak var subscriber: ErrorPropagatorSubscriber?

    public func report(error: Error) {
        subscriber?.error(propagator: self, error: error)
    }
}
