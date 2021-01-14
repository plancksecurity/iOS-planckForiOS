//
//  String+FPR.swift
//  pEpIOSToolbox
//
//  Created by Andreas Buff on 14.08.19.
//  Copyright © 2019 pEp Security SA. All rights reserved.
//

import Foundation

// MARK: - String+FPR

extension String {

    public typealias Fingerprint = String

    public var toValidFpr: String? {
        let alphaNumericOnly = self.alphaNumericOnly()
        let minLength = 16
        if alphaNumericOnly.count < minLength {
            return nil
        }

        return alphaNumericOnly
    }
}
