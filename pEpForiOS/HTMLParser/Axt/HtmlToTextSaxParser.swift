//
//  HtmlToTextSaxParser.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

class HtmlToTextSaxParser: BasicSaxParser {
    var tagStack = [String]()

    func parse(string: String) {
        super.parse(string: string, theDelegate: self)
    }

    let tagsAcceptingChars = Set<String>(["p", "div", "body", "b"])

    func acceptCharacters() -> Bool {
        if let elm = tagStack.last {
            return tagsAcceptingChars.contains(elm)
        }
        return false
    }
}

extension HtmlToTextSaxParser: AXHTMLParserDelegate {
    func parser(_ parser: AXHTMLParser, didStartElement elementName: String,
                attributes attributeDict: [AnyHashable : Any] = [:]) {
        tagStack.append(elementName)
        if elementName == "br" || elementName == "p" || elementName == "div" {
            add(string: "\n")
        }
    }

    func parser(_ parser: AXHTMLParser, didEndElement elementName: String) {
        tagStack.removeLast()
    }

    func parser(_ parser: AXHTMLParser, foundCharacters string: String) {
        if acceptCharacters() {
            add(string: string.replaceNewLinesWith(""))
        }
    }

    func parser(_ parser: AXHTMLParser, parseErrorOccurred parseError: Error) {
        Log.shared.error(component: #function, error: parseError)
    }
}
