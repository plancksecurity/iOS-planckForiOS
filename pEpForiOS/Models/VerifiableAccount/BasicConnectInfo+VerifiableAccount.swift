//
//  BasicConnectInfo+VerifiableAccount.swift
//  pEp
//
//  Created by Dirk Zimmermann on 16.04.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

import PantomimeFramework
import MessageModel

public extension BasicConnectInfo {
    init?(verifiableAccount: VerifiableAccountProtocol, emailProtocol: EmailProtocol) {
        guard let theAddress = verifiableAccount.address else {
            return nil
        }

        switch emailProtocol {
        case .imap:
            guard let severAddress = verifiableAccount.serverIMAP else {
                return nil
            }
            self.init(accountEmailAddress: theAddress,
                      loginName: verifiableAccount.loginName,
                      loginPassword: verifiableAccount.password,
                      accessToken: verifiableAccount.accessToken,
                      networkAddress: severAddress,
                      networkPort: verifiableAccount.portIMAP,
                      connectionTransport: verifiableAccount.transportIMAP,
                      authMethod: verifiableAccount.authMethod,
                      emailProtocol: emailProtocol)
        case .smtp:
            guard let severAddress = verifiableAccount.serverSMTP else {
                return nil
            }
            self.init(accountEmailAddress: theAddress,
                      loginName: verifiableAccount.loginName,
                      loginPassword: verifiableAccount.password,
                      accessToken: verifiableAccount.accessToken,
                      networkAddress: severAddress,
                      networkPort: verifiableAccount.portSMTP,
                      connectionTransport: verifiableAccount.transportSMTP,
                      authMethod: verifiableAccount.authMethod,
                      emailProtocol: emailProtocol)
        }
    }
}
