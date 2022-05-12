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
            ServerErrorInfo(
                            port: smtpConnection.port,
                            server: smtpConnection.server,
                            connectionTransport: smtpConnection.connectionTransport)))
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
                let serverErrorInfo = ServerErrorInfo(
                                port: smtpConnection.port,
                                server: smtpConnection.server,
                                connectionTransport: smtpConnection.connectionTransport)
                addError(SmtpSendError.connectionLost(#function, error.localizedDescription, serverErrorInfo))
                break
            }
        }

        if !setSpecializedError {
            // Did not find a more specific explanation for the error, so use the generic one
            let serverErrorInfo = ServerErrorInfo(
                            port: smtpConnection.port,
                            server: smtpConnection.server,
                            connectionTransport: smtpConnection.connectionTransport)
            addError(SmtpSendError.connectionLost(#function, nil, serverErrorInfo))
        }

        waitForBackgroundTasksAndFinish()
    }

    func connectionTerminated(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        let serverErrorInfo = ServerErrorInfo(
                        port: smtpConnection.port,
                        server: smtpConnection.server,
                        connectionTransport: smtpConnection.connectionTransport)

        addError(SmtpSendError.connectionTerminated(#function, serverErrorInfo))
        waitForBackgroundTasksAndFinish()
    }

    func connectionTimedOut(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {
        let serverErrorInfo = ServerErrorInfo(
                        port: smtpConnection.port,
                        server: smtpConnection.server,
                        connectionTransport: smtpConnection.connectionTransport)

        if let error = theNotification?.userInfo?[PantomimeErrorExtra] as? NSError {
            addError(SmtpSendError.connectionTimedOut(#function, error.localizedDescription, serverErrorInfo))
        } else {
            addError(SmtpSendError.connectionTimedOut(#function, nil, serverErrorInfo) )
        }
        waitForBackgroundTasksAndFinish()
    }

    func badResponse(_ smtpConnection: SmtpConnectionProtocol, response: String?) {
        let serverErrorInfo = ServerErrorInfo(
                        port: smtpConnection.port,
                        server: smtpConnection.server,
                        connectionTransport: smtpConnection.connectionTransport)

        addError(SmtpSendError.badResponse(#function, serverErrorInfo))
        waitForBackgroundTasksAndFinish()
    }

    func requestCancelled(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}
    func serviceInitialized(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}
    func serviceReconnected(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?) {}
}
