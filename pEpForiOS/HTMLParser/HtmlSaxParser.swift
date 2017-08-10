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
    let inputData: Data
    var output: String?

    var acceptCharacters = false

    init?(string: String) {
        if let data = string.data(using: String.Encoding.utf8) {
            self.inputData = data
        } else {
            return nil
        }
    }

    func parse() {
        let parser = XMLParser(data: inputData)
        parser.delegate = self
        let success = parser.parse()
        if !success {
            output = nil
        }
    }
}

extension HtmlSaxParser: XMLParserDelegate {
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

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        Log.shared.info(component: #function, content: "/\(elementName)")
        if elementName == "body" {
            acceptCharacters = false
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        Log.shared.info(component: #function, content: "\(string)")
        if acceptCharacters {
            print("\(string)")
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("error: \(parseError)")
    }
}
