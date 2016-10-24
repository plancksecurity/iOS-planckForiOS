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
    var connectionPort: UInt16 { get }
    var connectionAddress: String { get }
}

public class ConnectInfo: IConnectInfo {
    public var userId: String = ""
    public var userName: String?
    public var connectionAddress: String = ""
    public var connectionPort: UInt16 = 0
    
    public convenience init(userId: String, userName: String? = nil, connectionPort: UInt16, connectionAddress: String)
    {
        self.init(userId: userId, userName: nil, connectionPort: connectionPort, connectionAddress: connectionAddress)
    }
}

extension ConnectInfo: Hashable {
    public var hashValue: Int {
        return 31 &* userId.hashValue &+
            MiscUtil.optionalHashValue(userName) &+
            MiscUtil.optionalHashValue(connectionPort) &+
            MiscUtil.optionalHashValue(connectionAddress)
    }
}

extension ConnectInfo: Equatable {}

public func ==(l: ConnectInfo, r: ConnectInfo) -> Bool {
    return l.userId == r.userId && l.userName == r.userName && l.connectionPort == r.connectionPort &&
        l.connectionAddress == r.connectionAddress
}
