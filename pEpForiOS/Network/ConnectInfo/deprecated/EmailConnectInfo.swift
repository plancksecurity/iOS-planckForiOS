//
//  EmailConnectInfo
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 08/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

/**
 Holds additional connection info (like server, port etc.) for IMAP and SMTP.
 */
@available(*, deprecated, message: "use MMEmailConnectInfo instead")
public class EmailConnectInfo: ConnectInfo {
    enum EmailConnectInfoError: Error {
        case cannotFindServerCredentials
    }
    
    let emailProtocol: EmailProtocol?
    public let connectionTransport: ConnectionTransport?
    public let authMethod: AuthMethod?
    public let trusted: Bool

    /**
     There is either the `loginPassword`, or this, but there should never exist both.
     If non-nil, the `authMethod` is expected to be `AuthMethod.saslXoauth2`.
     */
    public var accessToken: OAuth2AccessTokenProtocol? {
        guard authMethod == .saslXoauth2,
            let key = loginPasswordKeyChainKey,
            let token = KeyChain.serverPassword(forKey: key) else {
                return nil
        }
        return OAuth2AccessToken.from(base64Encoded: token) as? OAuth2AccessTokenProtocol
    }

    init(accountObjectID: NSManagedObjectID,
         serverObjectID: NSManagedObjectID,
         credentialsObjectID: NSManagedObjectID,
         loginName: String? = nil,
         loginPasswordKeyChainKey: String? = nil,
         networkAddress: String,
         networkPort: UInt16,
         networkAddressType: NetworkAddressType? = nil,
         networkTransportType: NetworkTransportType? = nil,
         emailProtocol: EmailProtocol? = nil,
         connectionTransport: ConnectionTransport? = nil,
         authMethod: AuthMethod? = nil,
         trusted: Bool = false) {
        self.emailProtocol = emailProtocol
        self.connectionTransport = connectionTransport
        self.authMethod = authMethod
        self.trusted = trusted

        super.init(accountObjectID: accountObjectID,
                   serverObjectID: serverObjectID,
                   credentialsObjectID: credentialsObjectID,
                   loginName: loginName,
                   loginPasswordKeyChainKey: loginPasswordKeyChainKey,
                   networkAddress: networkAddress,
                   networkPort: networkPort,
                   networkAddressType: networkAddressType,
                   networkTransportType: networkTransportType)
    }

    func unsetNeedsVerificationAndFinish(context: NSManagedObjectContext) -> Error? {
        guard let creds = context.object(
            with: self.credentialsObjectID)
            as? CdServerCredentials else {
                return EmailConnectInfoError.cannotFindServerCredentials
        }

        if creds.needsVerification == true {
            creds.needsVerification = false
            if let cdAccount = creds.account {
                cdAccount.checkVerificationStatus()
            }
            context.saveAndLogErrors()
        }
        return nil
    }

    override public var hashValue: Int {
        return super.hashValue &+ (emailProtocol?.hashValue ?? 0)
            &+ (connectionTransport?.hashValue ?? 0)
            &+ (authMethod?.hashValue ?? 0)
            &+ trusted.hashValue
    }
}

public func ==(l: EmailConnectInfo, r: EmailConnectInfo) -> Bool {
    let sl = l as ConnectInfo
    let sr = r as ConnectInfo
    return sl == sr &&
        l.connectionTransport == r.connectionTransport &&
        l.authMethod == r.authMethod &&
        l.trusted == r.trusted
}

