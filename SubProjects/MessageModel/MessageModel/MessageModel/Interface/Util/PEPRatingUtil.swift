//
//  PEPRatingUtil.swift
//  MessageModel
//
//  Created by Martín Brude on 17/10/22.
//  Copyright © 2022 pEp Security S.A. All rights reserved.
//

import Foundation

public class PEPRatingUtil {

    /// Expose the init outside MM.
    public init() {}

    /// Indicate if the rating must be trusted because the recipient patterns matches the media key patterns
    ///
    /// - Parameter identities: The identities to check the email address domain
    /// - Returns: True if it must be trusted. False otherwise. False only means that there is no match with media key address pattern.
    public func outgoingMessageRatingMustBeTrusted(identities: [Identity.MMO], mediaKeys: [[String:String]]) -> Bool {
        var mustBeGreen = false
        guard let patterns = MediaKeysUtil().getPatterns(mediaKeyDictionaries: mediaKeys) else {
            // No patterns to check.
            return false
        }
        patterns.forEach { pattern in
            let trimmedPattern = pattern
                .replacingOccurrences(of: "*", with: "")
                .replacingOccurrences(of: "?", with: "")
            let expectedPattern = "[A-Z0-9a-z._%+-]+\(trimmedPattern)+\\.[A-Za-z]{2,64}"
            let emailRegex = try! NSRegularExpression(pattern: expectedPattern, options: [])
            identities.forEach { identity in
                if emailRegex.matchesWhole(string: identity.address) {
                    mustBeGreen = true
                }
            }
        }
        return mustBeGreen
    }

}
