//
//  NSAttributedString+Html.swift
//  pEp
//
//  Created by Adam Kowalski on 26/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

extension NSAttributedString {

    func toCitation(addCitationLevel: Bool = false) -> NSAttributedString {

        let htmlConversion = HtmlConversions()
        let attribStringWithGratherThanChars = htmlConversion
        .citedTextGratherThanChars(attribText: self,
                                   addCitationLevel: addCitationLevel)

        let attribStringWithVerticalLines = htmlConversion.citationGraterThanToVerticalLines(attribText: attribStringWithGratherThanChars)

        return attribStringWithVerticalLines
    }

    func toHtml() -> (plainText: String, html: String?) {

        let htmlDocAttribKey = [NSAttributedString.DocumentAttributeKey.documentType: NSAttributedString.DocumentType.html]

        // conversion NSTextAttachment with image to <img src.../> html tag with cid:{cid}

        let htmlConv = HtmlConversions()
        let plainTextAndHtml = htmlConv.citationVerticalLineToBlockquote(aString: self)
        let plainText = plainTextAndHtml.plainText

        let mutableAttribString = NSMutableAttributedString(attributedString: plainTextAndHtml.attribString)

        var images: [NSRange : String] = [:]

        mutableAttribString
            .enumerateAttribute(
                .attachment,
                in: mutableAttribString.wholeRange()) { (value, range, stop) in
                    if let attachment = value as? TextAttachment {
                        let delegate = ToMarkdownDelegate()
                        if let stringForAttachment = delegate.stringFor(attachment: attachment) {
                            if delegate.attachments.count > 0 {
                                images[range] = stringForAttachment.cleanAttachments
                            }
                        }
                    }
        }

        for item in images.sorted(by: { $0.key.location > $1.key.location }) {
            mutableAttribString.replaceCharacters(in: item.key, with: item.value)
        }

        guard let htmlData = try? mutableAttribString.data(from: mutableAttribString.wholeRange(),
                                                           documentAttributes: htmlDocAttribKey) else {
                                                            return (plainText: plainText, html: nil)
        }
        let html = (String(data: htmlData, encoding: .utf8) ?? "")
            .replaceMarkdownImageSyntaxToHtmlSyntax()
            .replacingOccurrences(of: "›", with: "<blockquote type=\"cite\">")
            .replacingOccurrences(of: "‹", with: "</blockquote>")

        return (plainText: plainText, html: html)
    }
}
