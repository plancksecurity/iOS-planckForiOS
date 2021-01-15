//
//  CdAccount+Trusted.swift
//  MessageModel
//
//  Created by Alejandro Gelos on 15/05/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

extension CdAccount {
    var isTrusted: Bool {
        guard let imapServer = server(type: .imap) else {
            return false
        }
        return imapServer.manuallyTrusted || imapServer.automaticallyTrusted
    }
}
