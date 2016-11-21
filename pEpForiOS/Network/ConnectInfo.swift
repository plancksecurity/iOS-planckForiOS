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
public protocol IConnectInfo: Hashable {
    /** The URI of the corresponding account object, for quick and unique access. */
    var accountObjectID: NSManagedObjectID { get }
    var userName: String { get }
    var networkAddress: String { get }
    var networkPort: UInt16 { get }
    var networkAddressType: NetworkAddressType? {get}
    var networkTransportType: NetworkTransportType? {get}
}

public class ConnectInfo: IConnectInfo {
    public var accountObjectID: NSManagedObjectID
    public var serverObjectID: NSManagedObjectID

    public var userName: String
    public var loginName: String?
    public var loginPassword: String?
    public var networkAddress: String
    public var networkPort: UInt16 = 0
    public var networkAddressType: NetworkAddressType?
    public var networkTransportType: NetworkTransportType?

    public init(accountObjectID: NSManagedObjectID, serverObjectID: NSManagedObjectID,
                userName: String, loginName: String?, loginPassword: String? = nil,
                networkAddress: String, networkPort: UInt16,
                networkAddressType: NetworkAddressType? = nil,
                networkTransportType: NetworkTransportType? = nil) {
        self.accountObjectID = accountObjectID
        self.serverObjectID = serverObjectID
        self.userName = userName
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
        return 31 &* accountObjectID.hashValue &+ serverObjectID.hashValue &+
            MiscUtil.optionalHashValue(userName) &+
            MiscUtil.optionalHashValue(networkPort) &+
            MiscUtil.optionalHashValue(networkAddress) &+
            MiscUtil.optionalHashValue(networkAddressType) &+
            MiscUtil.optionalHashValue(networkTransportType)
    }
}

extension ConnectInfo: Equatable {}

public func ==(l: ConnectInfo, r: ConnectInfo) -> Bool {
    return l.accountObjectID == r.accountObjectID
        && l.userName == r.userName
        && l.networkPort == r.networkPort
        && l.networkAddress == r.networkAddress
        && l.networkAddressType == r.networkAddressType
        && l.networkTransportType == r.networkTransportType
}
