//
//  ErrorPropagator.swift
//  pEp
//
//  Created by Xavier Algarra on 10/11/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol ErrorPropagatorSubscriber: class {
    func errorPropagator(_ propagator: ErrorPropagator, errorHasBeenReported error:Error)
}

class ErrorPropagator {
    weak var subscriber: ErrorPropagatorSubscriber?
    
    func report(error: Error) {
        subscriber?.errorPropagator(self, errorHasBeenReported: error)
    }
}
