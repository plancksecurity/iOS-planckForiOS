//
//  CdMessageIsAutoConsumeableTest.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 23.05.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest
import CoreData

import PEPObjCAdapterTypes_iOS
import PEPObjCAdapter_iOS
@testable import MessageModel

class CdMessageIsAutoConsumeableTest: PersistentStoreDrivenTestBase {
    func testNoAutoConsume() {
        let (cdMsg, _) = CdMessageCreation.validCdMessageAndAccount(context: moc)

        let header1 = CdHeaderField(context: moc)
        header1.name = "whatever"
        header1.value = "anything_but_yes"

        let header2 = CdHeaderField(context: moc)
        header2.name = "whatever2"
        header2.value = "anything_but_yes2"

        cdMsg.addToOptionalFields(header1)
        cdMsg.addToOptionalFields(header2)

        moc.saveAndLogErrors()

        XCTAssertFalse(cdMsg.isAutoConsumable)

        XCTAssertNil(CdMessage.first(predicate: CdMessage.PredicateFactory.isAutoConsumable(),
                                     orderedBy: nil,
                                     in: moc))
    }

    func testAutoConsume() {
        let (cdMsg, _) = CdMessageCreation.validCdMessageAndAccount(context: moc)

        let header1 = CdHeaderField(context: moc)
        header1.name = kPepHeaderAutoConsume
        header1.value = kPepValueAutoConsumeYes

        let header2 = CdHeaderField(context: moc)
        header2.name = "whatever2"
        header2.value = "anything_but_yes2"

        cdMsg.addToOptionalFields(header1)
        cdMsg.addToOptionalFields(header2)

        moc.saveAndLogErrors()

        XCTAssertTrue(cdMsg.isAutoConsumable)

        let cdMsg2 = CdMessage.first(predicate: CdMessage.PredicateFactory.isAutoConsumable(),
                                     orderedBy: nil,
                                     in: moc)
        XCTAssertNotNil(cdMsg2)
        XCTAssertEqual(cdMsg, cdMsg2)
    }

    func testAutoConsumeAmbigious() {
        let (cdMsg, _) = CdMessageCreation.validCdMessageAndAccount(context: moc)

        let header1 = CdHeaderField(context: moc)
        header1.name = kPepHeaderAutoConsume
        header1.value = kPepValueAutoConsumeYes

        let header2 = CdHeaderField(context: moc)
        header2.name = kPepHeaderAutoConsume
        header2.value = "anything_but_yes2"

        cdMsg.addToOptionalFields(header1)
        cdMsg.addToOptionalFields(header2)

        moc.saveAndLogErrors()

        XCTAssertTrue(cdMsg.isAutoConsumable)

        let cdMsg2 = CdMessage.first(predicate: CdMessage.PredicateFactory.isAutoConsumable(),
                                     orderedBy: nil,
                                     in: moc)
        XCTAssertNotNil(cdMsg2)
        XCTAssertEqual(cdMsg, cdMsg2)
    }

    func testInReplyToPositive() {
        let (cdMsg, _) = CdMessageCreation.validCdMessageAndAccount(context: moc)

        let _ = cdMsg.addMessageReference(messageID: CdMessage.inReplyToAutoConsume,
                                          referenceType: .inReplyTo,
                                          context: moc)

        moc.saveAndLogErrors()

        XCTAssertTrue(cdMsg.isAutoConsumable)

        let cdMsg2 = CdMessage.first(predicate: CdMessage.PredicateFactory.isAutoConsumable(),
                                     orderedBy: nil,
                                     in: moc)
        XCTAssertNotNil(cdMsg2)
        XCTAssertEqual(cdMsg, cdMsg2)
    }
}
