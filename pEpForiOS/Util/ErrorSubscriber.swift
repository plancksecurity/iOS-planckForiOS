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
        if let smtpError = error as? SmtpSendError {
            switch smtpError {
            case .authenticationFailed( _, let account):
                return accountErrorShouldBeShown(account: account, serverType: .smtp)
            case .illegalState(_):
                break
            case .connectionLost(_):
                break
            case .connectionTerminated(_):
                break
            case .connectionTimedOut(_):
                break
            case .badResponse(_):
                break
            case .clientCertificateNotAccepted:
                break
            }
        } else if let imapError = error as? ImapSyncOperationError {
            switch imapError {
            case .authenticationFailed(_, let account):
                return accountErrorShouldBeShown(account: account, serverType: .imap)
            case .illegalState(_):
                break
            case .connectionLost(_):
                break
            case .connectionTerminated(_):
                break
            case .connectionTimedOut(_):
                break
            case .folderAppendFailed:
                break
            case .badResponse(_):
                break
            case .actionFailed:
                break
            case .clientCertificateNotAccepted:
                break
            }
        }
        return true
    }
    private enum serverError {
        case smtp, imap
    }
    
    private func accountErrorShouldBeShown(account: String, serverType: serverError) -> Bool {
        guard let account = Account.by(address: account) else {
            return true
        }
        var server: Server
        
        switch serverType {
        case .imap:
            guard let imapServer = Server.by(account: account, serverType: .imap) else {
                return true
            }
            server = imapServer
            
        case .smtp:
            guard let smtpServer = Server.by(account: account, serverType: .smtp) else {
                return true
            }
            server = smtpServer
        }
        let actualDate = Date()
        guard let lastErrorShownDate = server.dateLastAuthenticationErrorShown,
        let minimumDateBeforeShowinAnotherError = Calendar.current.date(byAdding: .minute,
                                                                        value: 2,
                                                                        to: lastErrorShownDate)
            else {
                return true
        }
        if actualDate > minimumDateBeforeShowinAnotherError {
            server.dateLastAuthenticationErrorShown = actualDate
            Session.main.commit()
            return true
        } else {
            return false
        }
    }
}

extension ErrorSubscriber: ErrorPropagatorSubscriber {
    
    public func error(propagator: ErrorPropagator, error: Error) {
        if errorShouldBeDisplayed(error: error) {
            UIUtils.show(error: error)
        }
    }
}
