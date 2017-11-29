//
//  ErrorPropagator.swift
//  pEp
//
//  Created by Xavier Algarra on 10/11/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol subscriberError {
    func subscribe(view: handlerError)
}

protocol publisherError {
    func publish(error: Error)
}

protocol handlerError {
    func show(error:Error)
}

public class ErrorPropagator: subscriberError, publisherError {
    var delgate: handlerError?

    func subscribe(view: handlerError) {
        delgate = view
    }

    func publish(error: Error) {
        delgate?.show(error: error)
    }
}
