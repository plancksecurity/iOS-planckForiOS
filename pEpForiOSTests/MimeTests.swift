//
//  MimeTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 29/07/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

class MimeTests: XCTestCase {
    func testPGPMimePantomime() {
        guard
            let data = TestUtil.loadData(fileName: "PGPMimeMail.txt"),
            let cwMessage = CWMessage(data: data) else {
                XCTAssertTrue(false)
                return
        }
        let content = cwMessage.content()
        guard let multi = content as? CWMIMEMultipart  else {
            XCTAssertTrue(false)
            return
        }
        for i in 0..<multi.count() {
            let part = multi.part(at: i)
            let content = part.content()
            if let _ = content as? Data {
                // data
            } else if let _ = content as? NSString {
                // string
            } else {
                // multi?
            }
        }
    }
}
