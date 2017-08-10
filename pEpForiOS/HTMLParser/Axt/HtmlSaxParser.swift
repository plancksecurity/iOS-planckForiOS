//
//  HtmlSaxParser.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 10.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class HtmlSaxParser: NSObject {
    var output: String?

    var acceptCharacters = false

    func parse(string: String) {
        let parser = AXHTMLParser(htmlString: string)
        parser.delegate = self
        let success = parser.parse()
        if !success {
            output = nil
        }
    }

    func add(string: String) {
        output = "\(output ?? "")\(string)"
    }
}

extension HtmlSaxParser: AXHTMLParserDelegate {
    func parser(_ parser: AXHTMLParser, didStartElement elementName: String,
                attributes attributeDict: [AnyHashable : Any] = [:]) {
        if elementName == "body" {
            acceptCharacters = true
        } else if elementName == "img" {
            print("img!")
        } else if elementName == "br" {
            add(string: "\n")
        }
    }

    func parser(_ parser: AXHTMLParser, didEndElement elementName: String) {
        if elementName == "body" {
            acceptCharacters = false
        }
    }

    func parser(_ parser: AXHTMLParser, foundCharacters string: String) {
        if acceptCharacters {
            add(string: string)
        }
    }

    func parser(_ parser: AXHTMLParser, parseErrorOccurred parseError: Error) {
        Log.shared.error(component: #function, error: parseError)
    }
}
