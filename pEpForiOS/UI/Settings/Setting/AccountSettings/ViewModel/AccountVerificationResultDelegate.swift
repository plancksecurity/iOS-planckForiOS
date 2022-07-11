//
//  AccountVerificationResultDelegate.swift
//  pEp
//
//  Created by Dirk Zimmermann on 11.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

protocol AccountVerificationResultDelegate: AnyObject {
    func didVerify(result: AccountVerificationResult)
}
