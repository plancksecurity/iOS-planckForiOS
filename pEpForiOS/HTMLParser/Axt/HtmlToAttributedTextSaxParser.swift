//
//  HtmlToAttributedTextSaxParser.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

class HtmlToAttributedTextSaxParser: HtmlToTextSaxParser {
    var attributedOutput = NSAttributedString()

    override func add(string: String) {
        output = "\(output ?? "")\(string)"
    }

    override func parser(_ parser: AXHTMLParser, didStartElement elementName: String,
                attributes attributeDict: [AnyHashable : Any] = [:]) {
        if elementName == "img" {

        }
        super.parser(parser, didStartElement: elementName)
    }

    override func parser(_ parser: AXHTMLParser, foundCharacters string: String) {
        if acceptCharacters() {
            add(string: string.replaceNewLinesWith(""))
        }
    }
}
