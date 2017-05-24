//
//  AccountVerificationServiceProtocol.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

enum AccountVerificationError: Error {
    case networkError
    case loginErrorIMAP
    case loginErrorSMTP
}

enum AccountVerificationResult {
    case ok
    case error(VerificationError)
}

protocol AccountVerificationServiceDelegate {
    func verified(account: Account, service: VerificationServiceProtocol,
                  result: VerificationResult)
}

protocol AccountVerificationServiceProtocol: class {
    weak var delegate: VerificationServiceDelegate?
    func verify(account: Account)
}
