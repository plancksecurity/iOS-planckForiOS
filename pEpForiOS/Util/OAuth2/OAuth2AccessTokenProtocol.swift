//
//  OAuth2AccessTokenProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 12.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 After a successful authorization, use this to get access to tokens.
 */
public protocol OAuth2AccessTokenProtocol: NSSecureCoding {
    /**
     This object might be persisted into the keychain store. In that case,
     this key is used.
     */
    var keyChainID: String { get }

    // MARK: Refreshing tokens

    func performAction(
        freshTokensBlock: @escaping (_ error: Error?, _ accessToken: String?) -> Void)
}
