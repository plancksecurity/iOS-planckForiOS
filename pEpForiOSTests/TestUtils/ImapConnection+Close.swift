//
//  ImapConnection+Close.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 29.01.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

@testable import MessageModel

extension ImapConnection {
    func close() {
        // TODO
        //state.currentFolder = nil
        imapStore.close()
        imapStore.setDelegate(nil)
    }
}
