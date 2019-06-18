//
//  NSAttributedString+Extension.swift
//  pEp
//
//  Created by Andreas Buff on 20.09.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

extension NSAttributedString {
    // "Captures this:
    // "![Attached Image 1 (jpg)](cid:attached-inline-image-1-jpg-282FB9A8-824B-4AF5-B356-9F5C65BA69B3@pretty.Easy.privacy)"
    static let textAttachmentStringRegexPattern = "!\\[.+]\\(.+\\)"

    /// Strips attribute infomation from `string` value.
    ///
    /// - Returns: cleaned `string` value
    static func cleanNSAttributedStingAttributes(from str: String) -> String {
        // Currently strips NSTextAttachment ralated information only. More stuff might need to be
        // stripped, e.g. font information.
        return str.stringByRemovingRegexMatches(of: NSAttributedString.textAttachmentStringRegexPattern)
    }
}

extension String {
    /// Strips NSAttributedString attribute text representaions.
    ///
    /// - Returns: cleaned `string` value
    func stringCleanedFromNSAttributedStingAttributes() -> String {
        // Currently strips NSTextAttachment ralated information only. More stuff might need to be
        // stripped, e.g. font information.
        return NSAttributedString.cleanNSAttributedStingAttributes(from: self)
    }
}
