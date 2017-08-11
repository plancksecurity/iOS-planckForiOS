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
     Text from HTML, useful for creating snippets of a mail.
     */
    public func extractTextFromHTML() -> String? {
        return htmlToSimpleMarkdown()?.replaceNewLinesWith(" ").trimmedWhiteSpace()
    }

    /**
     Very simple markdown text from HTML.
     */
    public func htmlToSimpleMarkdown(
        imgDelegate: MarkdownImageDelegate? = nil) -> String? {
        let parser = HtmlToMarkdownSaxParser()
        parser.imgDelegate = imgDelegate
        parser.parse(string: self)
        return parser.output
    }
}
