//
//  LoginProtocol.swift
//  pEp
//
//  Created by Sascha Bacardit on 6/3/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

protocol loginprotocol {
    //Move to constructor, these are required for the class to respond
    func initialize(loginProtocolErrorDelegate: LoginProtocolResponseDelegate)
    //Login via usrname+password
    func login(emailAddress: String,
               displayName: String,
               password: String)
    
    //login via OAuth
    func loginWithOAuth2(viewController: UIViewController)

}
protocol LoginProtocolResponseDelegate: AnyObject {
    /**
     Called to signal an error when logging in.
     */
    func handle(loginError: Error)
    /**
     Called to signal an error when logging via oauth.
     */
    func handle(oauth2Error: Error)
    /**
     Called once the login process is done.
     */
    func didVerify(result: AccountVerificationResult)
}
