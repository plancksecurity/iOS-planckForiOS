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

/*
 let moc = Session.main.moc
 let actualDate = Date()
 let server = CdServer.first(predicate: CdServer.PredicateFactory.smtpServerForAccount(account: smtpConnection.accountAddress), in: moc)
 guard let lastErrorShownDate = server?.dateLastAuthenticationErrorShown,
 let minimumDateBeforeShowinAnotherError = Calendar.current.date(byAdding: .minute,
 value: 2,
 to: lastErrorShownDate)
 else {
 addError(SmtpSendError.authenticationFailed(
 #function,
 smtpConnection.accountAddress))
 waitForBackgroundTasksAndFinish()
 return
 }
 if actualDate > minimumDateBeforeShowinAnotherError {
 addError(SmtpSendError.authenticationFailed(
 #function,
 smtpConnection.accountAddress))
 waitForBackgroundTasksAndFinish()
 server?.dateLastAuthenticationErrorShown = actualDate
 moc.saveAndLogErrors()
 }
 */
