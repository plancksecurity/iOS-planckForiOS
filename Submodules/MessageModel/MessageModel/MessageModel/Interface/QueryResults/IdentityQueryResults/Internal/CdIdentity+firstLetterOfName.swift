//
//  CdIdentity+firstLetterOfName.swift
//  MessageModel
//
//  Created by Xavier Algarra on 09/10/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

// Mark: - NSFetchResults calculated field
extension CdIdentity {

    /// Calculated field that retrives the first letter of the name.
    @objc
    var firstLetterOfName: String {
        get {
            if let first = userName?.prefix(ofLength: 1), first.isLetter {
                return first
            } else {
                return NSLocalizedString("Unknown Name", comment: "section title for identity without username")
            }
        }
    }
}
