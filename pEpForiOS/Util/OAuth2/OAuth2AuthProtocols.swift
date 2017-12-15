//
//  OAuth2Protocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 13.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 The part that an application delegate interacts with.
 */
protocol OAuth2AuthorizationURLHandlerProtocol {
    /**
     Will try to match the given URL with the ongoing authorization.
     If there is a match, true is returned. Otherwise, that URL means something else.
     */
    func processAuthorizationRedirect(url: URL) -> Bool
}
