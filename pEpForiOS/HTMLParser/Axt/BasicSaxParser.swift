//
//  BasicSaxParser.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

class BasicSaxParser: NSObject {
    var output: String?

    func parse(string: String, theDelegate: AXHTMLParserDelegate) {
        let parser = AXHTMLParser(htmlString: string)
        parser.delegate = theDelegate
        let success = parser.parse()
        if !success {
            output = nil
        }

        output = output?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func add(string: String) {
        output = "\(output ?? "")\(string)"
    }
}
