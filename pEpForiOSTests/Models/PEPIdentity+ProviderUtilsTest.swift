//
//  PEPIdentity+ProviderUtilsTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 29.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
import MessageModel

class PEPIdentity_ProviderUtilsTest: XCTestCase {
    let address = "testee@peptest.ch"
    let gmailAddress = "test@gmail.com"
    var appendHandledByProvider: [String:[FolderType]]!
    let folderTypes = FolderType.allValuesToCheckFromServer
    
    override func setUp() {
        super.setUp()
        appendHandledByProvider = [gmailAddress:[.sent]]
    }

    // MARK: - providerDoesHandleAppend

    func testProviderDoesHandleAppend_non_gmail() {
        assertCorrectProviderDoesHandleAppendHandling(forAccountWithAddress: address)
    }

    func testProviderDoesHandleAppend_gmail() {
        assertCorrectProviderDoesHandleAppendHandling(forAccountWithAddress: gmailAddress)
    }

    // MARK: - HELPER

    private func assertCorrectProviderDoesHandleAppendHandling(forAccountWithAddress address: String) {
        let testee = PEPIdentity(address: address)
        for type in folderTypes {
            if  let typesHandledByProvider = appendHandledByProvider[address],
                typesHandledByProvider.contains(type) {
                XCTAssertTrue(testee.providerDoesHandleAppend(forFolderOfType: type))
            } else {
                XCTAssertFalse(testee.providerDoesHandleAppend(forFolderOfType: type))
            }
        }
    }
}
