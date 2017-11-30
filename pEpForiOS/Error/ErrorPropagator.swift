//
//  ErrorPropagator.swift
//  pEp
//
//  Created by Xavier Algarra on 10/11/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

public protocol ErrorPropagatorSubscriber: class {
    func errorPropagator(_ propagator: ErrorPropagator, errorHasBeenReported error:Error)
}

public class ErrorPropagator {
    public weak var subscriber: ErrorPropagatorSubscriber?

    public func report(error: Error) {
        subscriber?.errorPropagator(self, errorHasBeenReported: error)
    }
}
