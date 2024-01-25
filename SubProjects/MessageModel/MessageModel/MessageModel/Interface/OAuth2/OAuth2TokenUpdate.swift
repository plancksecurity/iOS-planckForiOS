//
//  OAuth2TokenUpdate.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 25/1/24.
//  Copyright © 2024 pEp Security S.A. All rights reserved.
//

import Foundation

import PlanckToolbox

public class OAuth2TokenUpdate {
    static public func updateToken(credentials: CdServerCredentials,
                                   accountEmail: String,
                                   accessToken: OAuth2AccessTokenProtocol) {
        Log.shared.logInfo(message: "Update credentials \(credentials)")
    }

    static public func updateTokens(accountEmail: String, accessToken: OAuth2AccessTokenProtocol) {
        let session = Session()
        session.perform {
            let moc = session.moc
            if let account = CdAccount.by(address: accountEmail, context: moc) {
                if let servers = account.servers {
                    for server in servers {
                        if let server = server as? CdServer {
                            if let credentials = server.credentials {
                                updateToken(credentials: credentials,
                                            accountEmail: accountEmail,
                                            accessToken: accessToken)
                            }
                        }
                    }
                }
            }
        }
    }
}
