//
//  MMConnectInfo.swift
//  pEp
//
//  Created by Andreas Buff on 23.07.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

class MMConnectInfo: Hashable {
    public let account: Account
    public let server: Server
    public let credentials: ServerCredentials
    
    public let loginName: String?
    public let loginPasswordKeyChainKey: String?
    public var loginPassword: String? {
        guard let key = loginPasswordKeyChainKey else {
            return nil
        }
        return KeyChain.serverPassword(forKey: key)
    }
    public let networkAddress: String
    public let networkPort: UInt16
    public let networkAddressType: NetworkAddressType?
    public let networkTransportType: NetworkTransportType?
    
    public init(account: Account,
                server: Server,
                credentials: ServerCredentials,
                loginName: String? = nil,
                loginPasswordKeyChainKey: String? = nil,
                networkAddress: String,
                networkPort: UInt16,
                networkAddressType: NetworkAddressType? = nil,
                networkTransportType: NetworkTransportType? = nil) {
        self.account = account
        self.server = server
        self.credentials = credentials
        self.loginName = loginName
        self.loginPasswordKeyChainKey = loginPasswordKeyChainKey
        self.networkAddress = networkAddress
        self.networkPort = networkPort
        self.networkAddressType = networkAddressType
        self.networkTransportType = networkTransportType
    }
    
    // MARK: Hashable
    
    /**
     If this was in an extension, the subclasses could not override it. Therefore, it's here.
     */
    var hashValue: Int {
        return 31 &*
            account.hashValue &+
            server.address.hashValue &+
            credentials.loginName.hashValue &+
            MiscUtil.optionalHashValue(loginName) &+
            MiscUtil.optionalHashValue(networkAddress) &+
            MiscUtil.optionalHashValue(networkPort) &+
            MiscUtil.optionalHashValue(networkAddressType) &+
            MiscUtil.optionalHashValue(networkTransportType)
    }
}

extension MMConnectInfo: Equatable {}

func ==(l: MMConnectInfo, r: MMConnectInfo) -> Bool {
    return l.hashValue == r.hashValue
}

// MARK: Retrieving the account object in an async, safe way

import MessageModel

extension MMConnectInfo {
    //    func handleCdAccount(handler: @escaping (CdAccount) -> ()) {
    //        let context = Record.Context.background
    //        context.perform { [weak self] in
    //            if let theSelf = self, let cdAccount = context.object(
    //                with: theSelf.accountObjectID) as? CdAccount {
    //                handler(cdAccount)
    //            }
    //        }
    //    }
    //
    //    func handleAccount(handler: @escaping (Account) -> ()) {
    //        handleCdAccount() { cdAccount in
    //            handler(cdAccount.account())
    //        }
    //    }
}
