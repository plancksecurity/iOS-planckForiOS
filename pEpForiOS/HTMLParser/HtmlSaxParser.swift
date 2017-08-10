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
    }
}

extension HtmlSaxParser: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        Log.shared.info(component: #function, content: "\(elementName)")
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        Log.shared.info(component: #function, content: "/\(elementName)")
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        Log.shared.info(component: #function, content: "\(string)")
    }
}
