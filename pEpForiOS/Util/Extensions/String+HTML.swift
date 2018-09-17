//
//  String+HTML.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 10.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

extension String {
    /**
     Extracts pure text from HTML, useful for creating snippets of a mail.
     */
    public func extractTextFromHTML() -> String? {
        let parser = HtmlToTextSaxParser()
        parser.parse(string: self)
        return parser.output?.replaceNewLinesWith(" ").trimmed()
    }

    /**
     Very simple markdown text from the HTML that is produced when converting
     an NSAttributedString to HTML.
     */
    public func attributedStringHtmlToMarkdown(
        imgDelegate: MarkdownImageDelegate? = nil) -> String? {
        let parser = HtmlToMarkdownSaxParser()
        parser.imgDelegate = imgDelegate
        parser.parse(string: self)
        return parser.output
    }

    public func markdownToHtml() -> String? {
        return (self as NSString).nsMarkdownToHtml()
    }

    public func htmlToAttributedString(
        attachmentDelegate: HtmlToAttributedTextSaxParserAttachmentDelegate?) -> NSAttributedString {
        let parser = HtmlToAttributedTextSaxParser()
        parser.attachmentDelegate = attachmentDelegate
        parser.parse(string: self)
        return parser.attributedOutput
    }
}
