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
protocol OAuth2AccessTokenProtocol {
    // MARK: Persistence

    static func from(base64Encoded: String) -> OAuth2AccessTokenProtocol?
    func persistIntoString() -> String

    // MARK: Refreshing tokens

    func performAction(
        freshTokensBlock: @escaping (_ error: Error?, _ accessToken: String?) -> Void)
}
