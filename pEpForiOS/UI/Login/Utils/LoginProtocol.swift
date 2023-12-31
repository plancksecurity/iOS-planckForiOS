//
//  LoginProtocol.swift
//  pEp
//
//  Created by Sascha Bacardit on 6/3/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

/// Expected login flow, frm the login start functions to the delegate responses.
protocol LoginProtocol {
    
    func login(emailAddress: String,
               displayName: String,
               password: String)
    
    func loginWithOAuth2(viewController: UIViewController)

}
protocol LoginProtocolResponseDelegate: AnyObject {

    /**
     Called to signal an error when logging in.
     */
    func didFail(error: Error)

    /**
     Called once the login process is done.
     */
    func didVerify(result: AccountVerificationResult)
}
