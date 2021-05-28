//
//  LoginViewModelOAuth2ErrorDelegate.swift
//  pEp
//
//  Created by Dirk Zimmermann on 15.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol LoginViewModelOAuth2ErrorDelegate: AnyObject {
    /**
     Called to signal an OAuth2 error.
     */
    func handle(oauth2Error: Error)
}
