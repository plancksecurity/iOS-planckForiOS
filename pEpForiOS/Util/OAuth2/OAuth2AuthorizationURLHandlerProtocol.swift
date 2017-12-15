//
//  OAuth2AuthorizationURLHandlerProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 15.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 Typically invoked by an app delegate that wants to handle a URL that might be the
 redirect of a recently triggered OAuth2 authorization request.
 */
protocol OAuth2AuthorizationURLHandlerProtocol {
    /**
     Will try to match the given URL with the ongoing authorization.
     If there is a match, true is returned. Otherwise, that URL means something else.
     */
    func processAuthorizationRedirect(url: URL) -> Bool
}
