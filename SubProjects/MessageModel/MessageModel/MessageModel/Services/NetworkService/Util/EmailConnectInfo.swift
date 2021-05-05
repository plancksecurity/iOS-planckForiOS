//
//  EmailConnectInfo.swift
//  pEp
//
//  Created by Andreas Buff on 23.07.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import CoreData

import PantomimeFramework

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

extension ConnectionTransport {
    init?(fromInt: Int?) {
        guard let i = fromInt else {
            return nil
        }
        switch i {
        case ConnectionTransport.plain.rawValue:
            self = ConnectionTransport.plain
        case ConnectionTransport.startTLS.rawValue:
            self = ConnectionTransport.startTLS
        case ConnectionTransport.TLS.rawValue:
            self = ConnectionTransport.TLS
        default:
            return nil
        }
    }

    // XXX: Here material from the Model area is used: to be avoided or code-shared.
    func toServerTransport() -> Server.Transport {
        switch self {
        case .plain:
            return Server.Transport.plain
        case .TLS:
            return Server.Transport.tls
        case .startTLS:
            return Server.Transport.startTls
        @unknown default:
            Log.shared.errorAndCrash("Unhandled case")
            return Server.Transport.plain
        }
    }
}

enum EmailProtocol: String {
    case smtp = "SMTP"
    case imap = "IMAP"

    init?(emailProtocol: String) {
        switch emailProtocol {
        case EmailProtocol.smtp.rawValue:
            self = .smtp
        case EmailProtocol.imap.rawValue:
            self = .imap
        default:
            return nil
        }
    }

    init?(serverType: Server.ServerType?) {
        guard let st = serverType else {
            return nil
        }
        switch st {
        case .imap:
            self = .imap
        case .smtp:
            self = .smtp
        }
    }
}

class EmailConnectInfo: ConnectInfo {

    let emailProtocol: EmailProtocol
    let connectionTransport: ConnectionTransport
    let authMethod: AuthMethod

    init(account: CdAccount,
         server: CdServer,
         credentials: CdServerCredentials,
         loginName: String? = nil,
         networkAddress: String,
         networkPort: UInt16,
         emailProtocol: EmailProtocol,
         connectionTransport: ConnectionTransport,
         authMethod: AuthMethod) {
        self.emailProtocol = emailProtocol
        self.connectionTransport = connectionTransport
        self.authMethod = authMethod

        super.init(account: account,
                   server: server,
                   credentials: credentials,
                   loginName: loginName,
                   networkAddress: networkAddress,
                   networkPort: networkPort)
    }

    func cdAccount(moc: NSManagedObjectContext) -> CdAccount? {
        return moc.cdAccount(from: accountObjectID)
    }

    func isTrusted(context: NSManagedObjectContext) -> Bool {
        var isTrusted = false
        context.performAndWait {
            guard let cdAccount = cdAccount(moc: context) else {
                Log.shared.errorAndCrash(message: "Need existing account")
                isTrusted = false
                return
            }
            isTrusted = cdAccount.isTrusted
        }
        return isTrusted
    }

    /// There is either the `loginPassword`, or this, but there should never exist both.
    /// If non-nil, the `authMethod` is expected to be `AuthMethod.saslXoauth2`.
    func accessToken() -> OAuth2AccessTokenProtocol? {
        if authMethod == .saslXoauth2,
            let payload = loginPassword {
            #if EXT_SHARE
            NSKeyedUnarchiver.setClass(OAuth2AccessToken.classForCoder(),
                                       forClassName: "MessageModel.OAuth2AccessToken")
            #endif
            return OAuth2AccessToken.from(base64Encoded: payload) as? OAuth2AccessTokenProtocol
        } else {
            return nil
        }
    }
}
