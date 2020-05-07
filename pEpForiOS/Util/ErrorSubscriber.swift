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
    var showedAccountsError = [String:Bool]()
    public func errorShouldBeDisplayed(error: Error) -> Bool{
        return true
    }
    
}

extension ErrorSubscriber: ErrorPropagatorSubscriber {
    
    public func error(propagator: ErrorPropagator, error: Error) {
        if errorShouldBeDisplayed(error: error) {
            UIUtils.show(error: error)
        }
    }
}
