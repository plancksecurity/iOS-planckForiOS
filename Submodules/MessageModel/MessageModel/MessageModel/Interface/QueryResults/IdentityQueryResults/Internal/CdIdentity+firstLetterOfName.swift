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
    /// Calculated field that retrives the first letter of the user name,
    /// or "#" if the first character is not a letter, or there is no user name.
    @objc
    var firstLetterOfName: String {
        get {
            if let first = userName?.prefix(ofLength: 1), first.isLetter {
                return first
            } else {
                return "#"
            }
        }
    }
}
