//
//  PEPMessage+OriginalHeaders.swift
//  MessageModel
//
//  Created by Andreas Buff on 26.09.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import PEPObjCAdapterTypes_iOS
import PEPObjCAdapter_iOS


extension PEPMessage {

    func removeOriginalRatingHeader() {
        let headersToIgnore = Set(["X-EncStatus".lowercased()])
        var newHeaders = [[String]]()
        guard let theHeaders = self.optionalFields else {
            // Nothing to do
            return
        }
        for aHeader in theHeaders {
            if aHeader.count == 2 {
                let headerName = aHeader[0]
                if !headersToIgnore.contains(headerName.lowercased()) {
                    newHeaders.append(aHeader)
                }
            }
        }
        if theHeaders.count != newHeaders.count {
            optionalFields = newHeaders
        }
    }
}
