//
//  OAuth2TokenUpdate.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 25/1/24.
//  Copyright © 2024 pEp Security S.A. All rights reserved.
//

import Foundation

import PlanckToolbox

/// Functionality for updating OAuth2 tokens
public class OAuth2TokenUpdate {
    static public func updateToken(credentials: CdServerCredentials,
                                   accountEmail: String,
                                   payload: String,
                                   keysAlreadyUpdated: inout Set<String>) {
        if let key = credentials.key {
            if !keysAlreadyUpdated.contains(key) {
                KeyChain.updateCreateOrDelete(password: payload, forKey: key)
                keysAlreadyUpdated.insert(key)
            }
        }
    }

    /// Updates all tokens in credentials for the account represented by the given email with the given access token.
    static public func updateTokens(accountEmail: String, accessToken: OAuth2AccessTokenProtocol) {
        let session = Session()
        session.perform {
            let moc = session.moc
            if let account = CdAccount.by(address: accountEmail, context: moc) {
                let payload = accessToken.persistBase64Encoded()
                var keysAlreadyUpdated = Set<String>()
                if let servers = account.servers {
                    for server in servers {
                        if let server = server as? CdServer {
                            if let credentials = server.credentials {
                                updateToken(credentials: credentials,
                                            accountEmail: accountEmail,
                                            payload: payload,
                                            keysAlreadyUpdated: &keysAlreadyUpdated)
                            }
                        }
                    }
                }
            }
        }
    }
}
