//
//  URL+MailTo.swift
//  pEp
//
//  Created by Andreas Buff on 03.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation


/// Handle mailto: URLs here.
extension URL {
    static let schemeMailto = "mailto:"

    /// Primitive addess parser.
    ///
    /// Exapmle supported URLs:
    /// "mailto:someone@example.com",
    /// "mailto:someone@example.com?cc=someone_else@example.com&subject=This%20is%20the%20subject&body=This%20is%20the%20body"
    ///
    /// - Returns: the first address of a mailto: URL if parseable, nil otherwize
    func firstRecipientAddress() -> String? {
        let schemeStriped = absoluteString.replacingOccurrences(of: URL.schemeMailto, with: "")
        var result: String?
        if schemeStriped.contains(find: "?") {
            result = schemeStriped.components(separatedBy: "?").first
        } else {
            result = schemeStriped
        }
        let isValid = result?.isProbablyValidEmail() ?? false
        return isValid ? result : nil
    }
}
