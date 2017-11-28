//
//  EmailValidatiorTest.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 25/07/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest
import UIKit

import pEpForiOS
import MessageModel

class EmailValidatorTest: XCTestCase {
    func testStandardAddress() {
        let emailAddressValidation = EmailAddressValidation(
            address: "iostest010@d-o.mainf-ak.e.com")
        XCTAssertTrue(emailAddressValidation.result)
    }

    func testMultipleArrobaAddress() {
        let emailAddressValidation = EmailAddressValidation(address: "ios@test010@mail.com")
        XCTAssertTrue(emailAddressValidation.result)
    }

    func testIpv4Address() {
        let emailAddressValidation = EmailAddressValidation(address: "iostest010@192.168.0.0")
        XCTAssertTrue(emailAddressValidation.result)
    }

    func testIpv6Address() {
        let emailAddressValidation = EmailAddressValidation(
            address: "iostest010@2001:0db8:85a3::1319:8a2e:0370:7344")
        XCTAssertTrue(emailAddressValidation.result)
    }

    func testWrongDomainAddress() {
        let emailAddressValidation = EmailAddressValidation(address: "iostest010@fake&&domain.com")
        XCTAssertTrue(emailAddressValidation.result)
    }

    func testWrongNameAddress() {
        let emailAddressValidation = EmailAddressValidation(address: "iostest010 @peptest.ch")
        XCTAssertTrue(emailAddressValidation.result)
    }
}
