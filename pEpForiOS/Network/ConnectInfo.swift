//
//  ConnectInfo.swift
//  pEpForiOS
//
//  Created by hernani on 24/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 Holds basic info to connect to peers (perhaps servers).
 */
public protocol IConnectInfo: Hashable {
    var userId: String { get } // identification (unique)
    var userName: String? { get } // display (repeatable)
    var networkPort: UInt16 { get }
    var networkAddress: String { get }
}

public class ConnectInfo: IConnectInfo {
    public var userId: String = ""
    public var userName: String?
    public var networkAddress: String = ""
    public var networkPort: UInt16 = 0
    
    public convenience init(userId: String, userName: String? = nil, networkPort: UInt16, networkAddress: String)
    {
        self.init(userId: userId, userName: nil, networkPort: networkPort, networkAddress: networkAddress)
    }
}

extension ConnectInfo: Hashable {
    public var hashValue: Int {
        return 31 &* userId.hashValue &+
            MiscUtil.optionalHashValue(userName) &+
            MiscUtil.optionalHashValue(networkPort) &+
            MiscUtil.optionalHashValue(networkAddress)
    }
}

extension ConnectInfo: Equatable {}

public func ==(l: ConnectInfo, r: ConnectInfo) -> Bool {
    return l.userId == r.userId && l.userName == r.userName && l.networkPort == r.networkPort &&
        l.networkAddress == r.networkAddress
}
