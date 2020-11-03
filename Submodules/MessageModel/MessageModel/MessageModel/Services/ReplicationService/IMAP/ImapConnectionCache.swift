//
//  ImapConnectionDataCache.swift
//  pEp
//
//  Created by Andreas Buff on 02.03.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

class ImapConnectionCache {
    private var imapConnectionCache = [EmailConnectInfo: ImapConnection]()

    var connectInfos: [EmailConnectInfo] {
        return Array(imapConnectionCache.keys)
    }

    func reset() {
        imapConnectionCache = [EmailConnectInfo: ImapConnection]()
    }

    func imapConnection(for connectInfo: EmailConnectInfo) -> ImapConnection {
        if let cachedData = imapConnectionCache[connectInfo] {
            let hasErrors = cachedData.hasError
            if !hasErrors {
                return cachedData
            }
        }

        let newData = ImapConnection(connectInfo: connectInfo)
        imapConnectionCache[connectInfo] = newData
        return newData
    }
}
