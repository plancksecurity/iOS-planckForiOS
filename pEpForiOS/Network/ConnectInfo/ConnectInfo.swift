//
//  MMConnectInfo.swift
//  pEp
//
//  Created by Andreas Buff on 23.07.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel
import pEpUtilities

enum NetworkAddressType: String {
    case ipv4 = "IPv4"
    case ipv6 = "IPv6"
    case dns = "DNS"
    case gns = "GNS" // GNU Name System (TBD)
}

enum NetworkTransportType: String {
    case udp = "UDP"
    case tcp = "TCP"
}

class ConnectInfo: Hashable {
    public let account: Account
    public let server: Server
    public let credentials: ServerCredentials

    public let loginName: String?
    public let loginPasswordKeyChainKey: String?
    public var loginPassword: String? {
        return credentials.password
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

extension ConnectInfo: Equatable {}

func ==(l: ConnectInfo, r: ConnectInfo) -> Bool {
    return l.hashValue == r.hashValue
}
