//
//  VerifiableAccountValidationError+LocalizedError.swift
//  pEp
//
//  Created by Dirk Zimmermann on 04.11.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

extension VerifiableAccountValidationError {
    // TODO This is duplicated in MM.
    public var errorDescription: String? {
        switch self {
        case .invalidUserData:
            return NSLocalizedString("Some fields are not valid. Please check all input fields.",
                                     comment: "Error description when failing to validate account fields (pEp4iOS)")
        case .unknown:
            return NSLocalizedString("Something went wrong.",
                                     comment: "Error description when something went wrong (pEp4iOS)")
        }
    }
}
