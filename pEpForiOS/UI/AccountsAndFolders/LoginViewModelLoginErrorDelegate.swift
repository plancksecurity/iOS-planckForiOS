//
//  LoginViewModelLoginErrorDelegate.swift
//  pEp
//
//  Created by Dirk Zimmermann on 15.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol LoginViewModelLoginErrorDelegate: class {
    /**
     Called to signal an error when logging in.
     */
    func handle(loginError: Error)
}
