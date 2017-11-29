//
//  ErrorPropagator.swift
//  pEp
//
//  Created by Xavier Algarra on 10/11/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol ErrorPropagatorSubscriber {
    func errorPropagator(_ propagator: ErrorPropagator, errorHasBeenReported error:Error)
}

class ErrorPropagator {
    var subscriber: ErrorPropagatorSubscriber?

    func subscribe(_ subscriber: ErrorPropagatorSubscriber) {
        self.subscriber = subscriber
    }

    func report(error: Error) {
        subscriber?.errorPropagator(self, errorHasBeenReported: error)
    }
}
