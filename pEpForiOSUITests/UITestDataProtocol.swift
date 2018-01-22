//
//  UITestDataProtocol.swift
//  pEpForiOSUITests
//
//  Created by Dirk Zimmermann on 10.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol UITestDataProtocol {
    static var workingAccount1: UIAccount { get }
    static var workingAccount2: UIAccount  { get }
    static var workingYahooAccount: UIAccount { get }
    static var gmailOAuth2Account: UIAccount { get }
    static var yahooOAuth2Account: UIAccount { get }
    static var manualAccount: UIAccount { get }
}
