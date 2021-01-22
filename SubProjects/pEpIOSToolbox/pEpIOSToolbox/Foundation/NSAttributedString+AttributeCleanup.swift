//
//  NSAttributedString+AttributeCleanup.swift
//  pEpIOSToolbox
//
//  Created by Andreas Buff on 24.09.19.
//  Copyright © 2019 pEp Security SA. All rights reserved.
//

import Foundation

extension NSAttributedString {
    // "Captures this:
    // "![Attached Image 1 (jpg)](cid:attached-inline-image-1-jpg-282FB9A8-824B-4AF5-B356-9F5C65BA69B3@pretty.Easy.privacy)"
    private static let textAttachmentStringRegexPattern = "!\\[.+]\\(.+\\)"

    /// Strips attribute infomation from `string` value.
    ///
    /// - Returns: cleaned `string` value
    public static func cleanNSAttributedStingAttributes(from str: String) -> String {
        // Currently strips NSTextAttachment ralated information only. More stuff might need to be
        // stripped, e.g. font information.
        return str.stringByRemovingRegexMatches(of: NSAttributedString.textAttachmentStringRegexPattern)
    }
}

extension String {
    /// Strips NSAttributedString attribute text representaions.
    ///
    /// - Returns: cleaned `string` value
    public func stringCleanedFromNSAttributedStingAttributes() -> String {
        // Currently strips NSTextAttachment ralated information only. More stuff might need to be
        // stripped, e.g. font information.
        return NSAttributedString.cleanNSAttributedStingAttributes(from: self)
    }
}
