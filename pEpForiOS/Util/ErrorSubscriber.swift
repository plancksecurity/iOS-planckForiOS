//
//  ErrorSubscriber.swift
//  pEp
//
//  Created by Xavier Algarra on 23/04/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel
import pEpIOSToolbox

public class ErrorSubscriber {
    private func errorShouldBeDisplayed(error: Error) -> Bool{
        if let smtpError = error as? SmtpSendError {
            switch smtpError {
            case .authenticationFailed(_, let account, _):
                return accountErrorShouldBeShown(account: account, serverType: .smtp)
            case .illegalState(_),
                 .connectionLost(_, _, _),
                 .connectionTerminated(_, _),
                 .connectionTimedOut(_, _, _),
                 .badResponse(_, _),
                 .clientCertificateNotAccepted:
                break
            }
        } else if let imapError = error as? ImapSyncOperationError {
            switch imapError {
            case .authenticationFailed(_, let account):
                return accountErrorShouldBeShown(account: account, serverType: .imap)
            case .illegalState(_),
                 .connectionLost(_),
                 .connectionTerminated(_),
                 .connectionTimedOut(_),
                 .folderAppendFailed,
                 .badResponse(_),
                 .actionFailed,
                 .clientCertificateNotAccepted:
                break
            }
        }
        return true
    }
    
    private enum serverError {
        case smtp, imap
    }
    
    private func accountErrorShouldBeShown(account: String, serverType: serverError) -> Bool {
        let accounts = Account.all()
        let firstAccount = accounts.first { (acc) -> Bool in
            return acc.user.address == account
        }
        guard let account = firstAccount else {
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
        let lastErrorShownDate = server.dateLastAuthenticationErrorShown
        
        if lastErrorShownDate == nil {
            server.dateLastAuthenticationErrorShown = actualDate
            Session.main.commit()
            return true
        }
        guard let lastErrorShown = lastErrorShownDate, let minimumDateBeforeShowinAnotherError = Calendar.current.date(byAdding: .minute, value: 2, to: lastErrorShown)
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
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("lost myself")
                return
            }
            if me.errorShouldBeDisplayed(error: error) {
                UIUtils.show(error: error)
            }
        }
    }
}
