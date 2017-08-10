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
}

extension HtmlSaxParser: AXHTMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        Log.shared.info(component: #function, content: "\(elementName)")
        if elementName == "body" {
            acceptCharacters = true
        } else if elementName == "img" {
            print("img!")
        } else if elementName == "br" {
            print("br!")
        }
    }

    func parser(_ parser: AXHTMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        Log.shared.info(component: #function, content: "/\(elementName)")
        if elementName == "body" {
            acceptCharacters = false
        }
    }

    func parser(_ parser: AXHTMLParser, foundCharacters string: String) {
        Log.shared.info(component: #function, content: "\(string)")
        if acceptCharacters {
            print("\(string)")
        }
    }

    func parser(_ parser: AXHTMLParser, parseErrorOccurred parseError: Error) {
        print("error: \(parseError)")
    }
}
