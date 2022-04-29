//
//  LoginSmtpOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 29/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import PantomimeFramework

class LoginSmtpOperation: ConcurrentBaseOperation {
    private var smtpConnection: SmtpConnectionProtocol

    init(parentName: String = #function,
         smtpConnection: SmtpConnectionProtocol,
         errorContainer: ErrorContainerProtocol = ErrorPropagator()) {
        self.smtpConnection = smtpConnection
        super.init(parentName: parentName, errorContainer: errorContainer)
    }

    override func main() {
        if isCancelled {
            waitForBackgroundTasksAndFinish()
            return
        }
        smtpConnection.delegate = self
        smtpConnection.start()
    }
}

extension LoginSmtpOperation: SmtpConnectionDelegate {
    func messageSent(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}
    func messageNotSent(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}
    func transactionInitiationCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}
    func transactionInitiationFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}
    func recipientIdentificationCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}
    func recipientIdentificationFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}
    func transactionResetCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}
    func transactionResetFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}

    func authenticationCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        self.waitForBackgroundTasksAndFinish()
    }
    
    func authenticationFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        addError(SmtpSendError.authenticationFailed(
            #function,
            smtpConnection.accountAddress,
            smtpConnection.displayInfo))
        waitForBackgroundTasksAndFinish()
    }
    
    func connectionEstablished(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}

    func connectionLost(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        var setSpecializedError = false

        if let error = theNotification?.userInfo?[PantomimeErrorExtra] as? NSError {
            switch Int32(error.code) {
            case errSSLPeerCertUnknown:
                addError(SmtpSendError.clientCertificateNotAccepted)
                setSpecializedError = true
            case errSSLClosedAbort:
                if smtpConnection.isClientCertificateSet {
                    addError(SmtpSendError.clientCertificateNotAccepted)
                    setSpecializedError = true
                }
            default:
                addError(SmtpSendError.connectionLost(#function, error.localizedDescription, smtpConnection.displayInfo))
                break
            }
        }

        if !setSpecializedError {
            // Did not find a more specific explanation for the error, so use the generic one
            addError(SmtpSendError.connectionLost(#function, nil, smtpConnection.displayInfo))
        }

        waitForBackgroundTasksAndFinish()
    }

    func connectionTerminated(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        addError(SmtpSendError.connectionTerminated(#function, smtpConnection.displayInfo))
        waitForBackgroundTasksAndFinish()
    }

    func connectionTimedOut(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        if let error = theNotification?.userInfo?[PantomimeErrorExtra] as? NSError {
            addError(SmtpSendError.connectionTimedOut(#function, error.localizedDescription, smtpConnection.displayInfo))
        } else {
            addError(SmtpSendError.connectionTimedOut(#function, nil, smtpConnection.displayInfo) )
        }
        waitForBackgroundTasksAndFinish()
    }

    func badResponse(_ smtpConnection: SmtpConnectionProtocol, response: String?) {
        addError(SmtpSendError.badResponse(#function, smtpConnection.displayInfo))
        waitForBackgroundTasksAndFinish()
    }

    func requestCancelled(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}
    func serviceInitialized(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}
    func serviceReconnected(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}
}
