//
//  Server+TrustedServer.swift
//  MessageModel
//
//  Created by Alejandro Gelos on 13/01/2020.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

extension Server {
    ///List of Servers that we advice to warn the user, before trusting
    //Feel free to append the list
    private var serversToWarnBeforeTrusting: Set<String> {
        return Set(["gmail", "gmx", "yahoo"])
    }

    /// Indicate if you should show a warning before trusting this server
    public var shouldShowWaringnBeforeTrusting: Bool {
        for server in serversToWarnBeforeTrusting {
            if address.contains(find: server) {
                return true
            }
        }
        return false
    }
}
