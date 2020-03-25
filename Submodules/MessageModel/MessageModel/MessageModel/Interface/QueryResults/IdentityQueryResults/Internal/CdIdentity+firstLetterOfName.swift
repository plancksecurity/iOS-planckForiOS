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
    /// The first letter of the user name, or "#" if the first character
    /// is not a letter or empty, or there is no user name at all.
    @objc
    var firstLetterOfName: String {
        get {
            guard let theUserName = userName as NSString? else {
                return "#"
            }
            return theUserName.firstLetterOfName()
        }
    }
}
