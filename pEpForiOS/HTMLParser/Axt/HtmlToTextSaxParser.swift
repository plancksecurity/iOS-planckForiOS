//
//  HtmlToTextSaxParser.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox

class HtmlToTextSaxParser: BasicSaxParser {
    var tagStack = [String]()

    func parse(string: String) {
        super.parse(string: string, theDelegate: self)
    }

    var tagsAcceptingChars = Set<String>(["p", "div", "body", "b", "td", "span", "font", "a"])

    override init() {
        for i in 1...20 {
            tagsAcceptingChars.insert("h\(i)")
        }
    }

    func acceptCharacters() -> Bool {
        if let elm = tagStack.last {
            return tagsAcceptingChars.contains(elm)
        }
        return false
    }

    func nestedInside(tag: String) -> Bool {
        return tagStack.contains(tag)
    }
}

extension HtmlToTextSaxParser: AXHTMLParserDelegate {
    func parser(_ parser: AXHTMLParser, didStartElement elementName: String,
                attributes attributeDict: [AnyHashable : Any] = [:]) {
        tagStack.append(elementName)
    }

    func parser(_ parser: AXHTMLParser, didEndElement elementName: String) {
        if elementName == "br" || elementName == "p" {
            add(string: "\n")
        }
        tagStack.removeLast()
    }

    func parser(_ parser: AXHTMLParser, foundCharacters string: String) {
        if acceptCharacters() {
            var toAppend = string
            if nestedInside(tag: "blockquote") {
                toAppend = "> \(toAppend)"
            }
            add(string: toAppend)
        }
    }

    func parser(_ parser: AXHTMLParser, parseErrorOccurred parseError: Error) {
        Log.shared.error("%@", "\(parseError)")
    }
}
