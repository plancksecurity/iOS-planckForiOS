//
//  UITestDataProtocol.swift
//  pEpForiOSUITests
//
//  Created by Dirk Zimmermann on 10.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol UITestDataProtocol {
    var workingAccount1: UIAccount { get }
    var workingAccount2: UIAccount  { get }
    var workingAccount3: UIAccount  { get }
    var workingYahooAccount: UIAccount { get }
    var gmailOAuth2Account: UIAccount { get }
    var yahooOAuth2Account: UIAccount { get }
    var manualAccount: UIAccount { get }
}
