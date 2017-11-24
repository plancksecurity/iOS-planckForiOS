//
//  EmailAddressValidation.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 24/07/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

public class EmailAddressValidation {

    public init(address: String, separator: String = "@") {
        self.addressComponents = address.components(separatedBy: separator)
        self.generalValidation()
        result = general
    }

    public var result = false

    private var general = false

    private var addressComponents : [String]?

    private func generalValidation() {
        if let s = addressComponents, s.count > 1 {
            if !s[0].isEmpty && !s[1].isEmpty {
                general = true
            }

        }
    }
}
