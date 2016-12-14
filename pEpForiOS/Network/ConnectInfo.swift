//
//  ConnectInfo.swift
//  pEpForiOS
//
//  Created by hernani on 24/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

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
public class ConnectInfo {
    public let accountObjectID: NSManagedObjectID
    public let serverObjectID: NSManagedObjectID
    public let credentialsObjectID: NSManagedObjectID

    public let loginName: String?
    public let loginPassword: String?
    public let networkAddress: String
    public let networkPort: UInt16
    public let networkAddressType: NetworkAddressType?
    public let networkTransportType: NetworkTransportType?

    public init(accountObjectID: NSManagedObjectID,
                serverObjectID: NSManagedObjectID,
                credentialsObjectID: NSManagedObjectID,
                loginName: String? = nil,
                loginPassword: String? = nil,
                networkAddress: String,
                networkPort: UInt16,
                networkAddressType: NetworkAddressType? = nil,
                networkTransportType: NetworkTransportType? = nil) {
        self.accountObjectID = accountObjectID
        self.serverObjectID = serverObjectID
        self.credentialsObjectID = credentialsObjectID
        self.loginName = loginName
        self.loginPassword = loginPassword
        self.networkAddress = networkAddress
        self.networkPort = networkPort
        self.networkAddressType = networkAddressType
        self.networkTransportType = networkTransportType
    }
}

extension ConnectInfo: Hashable {
    public var hashValue: Int {
        return 31 &*
            accountObjectID.hashValue &+
            serverObjectID.hashValue &+
            credentialsObjectID.hashValue &+
            MiscUtil.optionalHashValue(loginName) &+
            MiscUtil.optionalHashValue(loginPassword) &+
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
        && l.loginPassword == r.loginPassword
        && l.networkPort == r.networkPort
        && l.networkAddress == r.networkAddress
        && l.networkAddressType == r.networkAddressType
        && l.networkTransportType == r.networkTransportType
}
