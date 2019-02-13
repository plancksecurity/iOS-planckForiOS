//
//  ImapConnectionDataCache.swift
//  pEp
//
//  Created by Andreas Buff on 02.03.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

struct ImapConnectionDataCache {
    private var imapConnectionDataCache = [EmailConnectInfo: ImapSyncData]()

    var emailConnectInfos: [EmailConnectInfo] {
        return Array(imapConnectionDataCache.keys)
    }

    mutating func reset() {
        imapConnectionDataCache = [EmailConnectInfo: ImapSyncData]()
    }

    mutating func imapConnectionData(for connectInfo: EmailConnectInfo) -> ImapSyncData {
        if let cachedData = imapConnectionDataCache[connectInfo] {
            return cachedData
        }

        let newData = ImapSyncData(connectInfo: connectInfo)
        imapConnectionDataCache[connectInfo] = newData
        return newData
    }
}
