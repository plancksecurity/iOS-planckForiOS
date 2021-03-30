//
//  AccountVerificationResultDelegate.swift
//  pEp
//
//  Created by Dirk Zimmermann on 11.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

protocol AccountVerificationResultDelegate: class {
    func didVerify(result: AccountVerificationResult)
}
