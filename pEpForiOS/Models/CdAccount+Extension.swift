//
//  CdAccount+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

extension CdAccount {
    open var connectInfo: EmailConnectInfo {
        let password = KeyChain.password(key: self.email,
                                         serverType: (self.connectInfo.emailProtocol?.rawValue)!)
        
        return EmailConnectInfo.init(
            emailProtocol: self.connectInfo.emailProtocol!,
            userId: self.connectInfo.userId,
            userPassword: password,
            userName: self.connectInfo.userName,
            networkPort: self.connectInfo.networkPort,
            networkAddress: self.connectInfo.networkAddress,
            connectionTransport: self.connectInfo.connectionTransport,
            authMethod: self.connectInfo.authMethod
        )
    }

    open var rawImapTransport: ConnectionTransport {
        return ConnectionTransport(rawValue: self.imapTransport.intValue)!
    }

    open var rawSmtpTransport: ConnectionTransport {
        return ConnectionTransport(rawValue: self.smtpTransport.intValue)!
    }
}
