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
    public func extractTextFromHTML() -> String {
        let htmlData = data(using: String.Encoding.utf8)
        let doc = TFHpple(htmlData: htmlData, encoding: "UTF-8")
        let elms = doc?.search(withXPathQuery: "//body//text()[normalize-space()]")

        var result = ""
        for tmp in elms ?? [] {
            if let e = tmp as? TFHppleElement {
                let s = e.content.trimmedWhiteSpace()
                if !s.isEmpty {
                    if result.characters.count > 0 {
                        result.append(" " as Character)
                    }
                    result.append(s)
                }
            }
        }
        return result
    }

    /**
     Very simple markdown text from HTML.
     */
    public func htmlToSimpleMarkdown() -> String? {
        let parser = HtmlSaxParser()
        parser.parse(string: self)
        return parser.output
    }
}
