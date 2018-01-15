//
//  LoginViewModelErrorDelegate.swift
//  pEp
//
//  Created by Dirk Zimmermann on 15.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol LoginViewModelErrorDelegate: class {
    /**
     Called to signal error, e.g. when trying OAuth2.
     */
    func handle(error: Error)
}
