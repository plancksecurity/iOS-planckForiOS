//
//  TestUtil+LoadData.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 29.05.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import XCTest
import CoreData

import PantomimeFramework
import PEPObjCAdapterFramework
@testable import MessageModel

extension TestUtil {

    static func loadData(testClass: AnyClass, fileName: String) -> Data? {
        let testBundle = Bundle(for: testClass)
        guard let keyPath = testBundle.path(forResource: fileName, ofType: nil) else {
            XCTFail("Could not find file named \(fileName)")
            return nil
        }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: keyPath)) else {
            XCTFail("Could not load file named \(fileName)")
            return nil
        }
        return data
    }

    /**
     Loads the given file by name and parses it into a pantomime message.
     */
    static func cwImapMessage(testClass: AnyClass, fileName: String) -> CWIMAPMessage? {
        guard
            var msgTxtData = loadData(testClass: testClass,
                                      fileName: fileName)
            else {
                XCTFail()
                return nil
        }

        // This is what pantomime does with everything it receives
        msgTxtData = replacedCRLFWithLF(data: msgTxtData)

        let pantomimeMail = CWIMAPMessage(data: msgTxtData, charset: "UTF-8")
        pantomimeMail?.setUID(5) // some random UID out of nowhere
        pantomimeMail?.setFolder(CWIMAPFolder(name: ImapConnection.defaultInboxName))

        return pantomimeMail
    }

    /**
     Loads the given file by name, parses it with pantomime and creates a CdMessage from it.
     */
    static func cdMessage(testClass: AnyClass,
                          fileName: String,
                          cdOwnAccount: CdAccount) -> CdMessage? {
        guard let pantomimeMail = cwImapMessage(testClass: testClass, fileName: fileName) else {
            XCTFail()
            return nil
        }

        let moc: NSManagedObjectContext = Stack.shared.mainContext
        guard let cdMessage = CdMessage.insertOrUpdate(pantomimeMessage: pantomimeMail,
                                                       account: cdOwnAccount,
                                                       messageUpdate: CWMessageUpdate(),
                                                       context: moc)
            else {
                XCTFail()
                return nil
        }
        XCTAssertEqual(cdMessage.pEpRating, Int16(PEPRating.undefined.rawValue))

        return cdMessage
    }

    static func replacedCRLFWithLF(data: Data) -> Data {
        let mData = NSMutableData(data: data)
        mData.replaceCRLFWithLF()
        return mData as Data
    }
}
