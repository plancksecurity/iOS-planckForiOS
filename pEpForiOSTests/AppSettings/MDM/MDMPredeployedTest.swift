//
//  MDMPredeployedTest.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 19.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpForiOS
import pEp4iosIntern

class MDMPredeployedTest: XCTestCase {

    override func setUpWithError() throws {
        UserDefaults().removePersistentDomain(forName: kAppGroupIdentifier)
    }

    override func tearDownWithError() throws {
    }

    func testExample() throws {
    }

    // MARK: - Util

    let keyServerName = "name"
    let keyServerPort = "port"
    let keyUserName = "userName"
    let keyLoginName = "loginName"
    let keyPassword = "password"
    let keyImapServer = "imapServer"
    let keySmtpServer = "smtpServer"

    func serverDictionary(name: String, port: UInt16) -> NSDictionary {
        return [keyServerName: name, keyServerPort: NSNumber(value: port)]
    }

    func accountDictionary(userName: String,
                           loginName: String,
                           password: String,
                           imapServer: NSDictionary,
                           smtpServer: NSDictionary) -> NSDictionary {
        return [keyUserName: userName,
               keyLoginName: loginName,
                keyPassword: password,
              keyImapServer: imapServer,
              keySmtpServer: smtpServer]
    }
}
