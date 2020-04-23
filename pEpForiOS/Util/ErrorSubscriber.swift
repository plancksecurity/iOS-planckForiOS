//
//  ErrorSubscriber.swift
//  pEp
//
//  Created by Xavier Algarra on 23/04/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public class ErrorSubscriber {
    
}

extension ErrorSubscriber: ErrorPropagatorSubscriber {
    public func error(propagator: ErrorPropagator, error: Error) {
        UIUtils.show(error: error)
    }
}
