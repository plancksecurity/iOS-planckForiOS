//
//  ConnectInfo.swift
//  pEpForiOS
//
//  Created by hernani on 24/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

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
    var userId: String { get } // identification (unique)
    var userName: String? { get } // display (repeatable), optional
    var networkAddress: String { get }
    var networkPort: UInt16 { get }
    var networkAddressType: NetworkAddressType? {get}
    var networkTransportType: NetworkTransportType? {get}
}

public class ConnectInfo: IConnectInfo {
    public var userId: String = ""
    public var userName: String? // Optional
    public var networkAddress: String = ""
    public var networkPort: UInt16 = 0
    public var networkAddressType: NetworkAddressType? // Optional
    public var networkTransportType: NetworkTransportType? // Optional
    
    public convenience init(userId: String,
                            userName: String? = nil,
                            networkPort: UInt16,
                            networkAddress: String,
                            networkAddressType: NetworkAddressType? = NetworkAddressType.dns,
                            networkTransportType: NetworkTransportType? = NetworkTransportType.tcp)
    {
        self.init(userId: userId, userName: nil, networkPort: networkPort, networkAddress: networkAddress)
    }
}

extension ConnectInfo: Hashable {
    public var hashValue: Int {
        return 31 &* userId.hashValue &+
            MiscUtil.optionalHashValue(userName) &+
            MiscUtil.optionalHashValue(networkPort) &+
            MiscUtil.optionalHashValue(networkAddress) &+
            MiscUtil.optionalHashValue(networkAddressType) &+
            MiscUtil.optionalHashValue(networkTransportType)
    }
}

extension ConnectInfo: Equatable {}

public func ==(l: ConnectInfo, r: ConnectInfo) -> Bool {
    return l.userId == r.userId
        && l.userName == r.userName
        && l.networkPort == r.networkPort
        && l.networkAddress == r.networkAddress
        && l.networkAddressType == r.networkAddressType
        && l.networkTransportType == r.networkTransportType
}
