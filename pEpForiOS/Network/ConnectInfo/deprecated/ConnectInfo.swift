//
//  ConnectInfo.swift
//  pEpForiOS
//
//  Created by hernani on 24/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData
import MessageModel

public enum NetworkAddressType: String {
    case ipv4 = "IPv4"
    case ipv6 = "IPv6"
    case dns = "DNS"
    case gns = "GNS" // GNU Name System (TBD)
}

public enum NetworkTransportType: String {
    case udp = "UDP"
    case tcp = "TCP"
}

/**
 Holds basic info to connect to peers (perhaps servers).
 */
@available(*, deprecated, message: "use MMConnectInfo instead")
public class ConnectInfo: Hashable {
    public let accountObjectID: NSManagedObjectID
    public let serverObjectID: NSManagedObjectID
    public let credentialsObjectID: NSManagedObjectID

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

    public init(accountObjectID: NSManagedObjectID,
                serverObjectID: NSManagedObjectID,
                credentialsObjectID: NSManagedObjectID,
                loginName: String? = nil,
                loginPasswordKeyChainKey: String? = nil,
                networkAddress: String,
                networkPort: UInt16,
                networkAddressType: NetworkAddressType? = nil,
                networkTransportType: NetworkTransportType? = nil) {
        self.accountObjectID = accountObjectID
        self.serverObjectID = serverObjectID
        self.credentialsObjectID = credentialsObjectID
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
    public var hashValue: Int {
        return 31 &*
            accountObjectID.hashValue &+
            serverObjectID.hashValue &+
            credentialsObjectID.hashValue &+
            MiscUtil.optionalHashValue(loginName) &+
            MiscUtil.optionalHashValue(networkAddress) &+
            MiscUtil.optionalHashValue(networkPort) &+
            MiscUtil.optionalHashValue(networkAddressType) &+
            MiscUtil.optionalHashValue(networkTransportType)
    }
}

extension ConnectInfo: Equatable {}

public func ==(l: ConnectInfo, r: ConnectInfo) -> Bool {
    return l.accountObjectID == r.accountObjectID
        && l.loginName == r.loginName
        && l.networkPort == r.networkPort
        && l.networkAddress == r.networkAddress
        && l.networkAddressType == r.networkAddressType
        && l.networkTransportType == r.networkTransportType
}

// MARK: Retrieving the account object in an async, safe way

import MessageModel

extension ConnectInfo {
    func handleCdAccount(handler: @escaping (CdAccount) -> ()) {
        let context = Record.Context.background
        context.perform { [weak self] in
            if let theSelf = self, let cdAccount = context.object(
                with: theSelf.accountObjectID) as? CdAccount {
                handler(cdAccount)
            }
        }
    }

    func handleAccount(handler: @escaping (Account) -> ()) {
        handleCdAccount() { cdAccount in
            handler(cdAccount.account())
        }
    }
}
