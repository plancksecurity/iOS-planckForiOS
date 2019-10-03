//!!!: tests run forever
////
////  HandshakePartnerTableViewCellViewModelTests.swift
////  pEpForiOS
////
////  Created by Dirk Zimmermann on 18.09.17.
////  Copyright © 2017 p≡p Security S.A. All rights reserved.
////
//
//import XCTest
//
//@testable import MessageModel //FIXME:
//@testable import pEpForiOS
//import PEPObjCAdapterFramework
//
//class HandshakePartnerTableViewCellViewModelTests: CoreDataDrivenTestBase {
//
//    func importMail(session: PEPSession = PEPSession()) ->
//        (message: Message, mySelfID: Identity, partnerID: Identity)? {
//            guard
//                let (mySelf: mySelfID, partner: partnerID, message: message) =
//                TestUtil.setUpPepFromMail(emailFilePath: "HandshakeTests_mail_001.txt") else {
//                        XCTFail()
//                        return nil
//            }
//            XCTAssertNotEqual(mySelfID.address, partnerID.address)
//
//            let meIdent = mySelfID.pEpIdentity()
//            let partnerIdent = partnerID.pEpIdentity()
//
//            try! session.mySelf(meIdent)
//            try! session.update(partnerIdent)
//
//            XCTAssertNotNil(meIdent.fingerPrint)
//            XCTAssertNotNil(partnerIdent.fingerPrint)
//            XCTAssertTrue(try! partnerIdent.isPEPUser(session).boolValue)
//
//            XCTAssertEqual(partnerIdent.fingerPrint, "A90307CAA0B224105367BF677705867380346FCF")
//
//            return (message: message, mySelfID: mySelfID, partnerID: partnerID)
//    }
//
//    /// Tests trust/reset cycle without view model.
//    func testBasicTrustReset() {
//        let session = PEPSession()
//
//        guard
//            let (message: _, mySelfID: _, partnerID: partnerID) = importMail(session: session) else
//        {
//            XCTFail()
//            return
//        }
//
//        let partnerIdent = partnerID.pEpIdentity()
//        try! session.update(partnerIdent)
//
//        try! session.trustPersonalKey(partnerIdent)
//        try! session.update(partnerIdent)
//        XCTAssertTrue(try! partnerIdent.isPEPUser(session).boolValue)
//
//        try! session.keyResetTrust(partnerIdent)
//        try! session.trustPersonalKey(partnerIdent)
//        try! session.update(partnerIdent)
//        XCTAssertTrue(try! partnerIdent.isPEPUser(session).boolValue)
//    }
//
//    /**
//     Tests trust/reset/mistrust/resut cycle without view model, using a backup
//     to keep the comm type.
//     */
//    func testBasicTrustMistrustCycleUsingBackup() {
//        let session = PEPSession()
//
//        guard
//            let (message: _, mySelfID: mySelfID,
//                 partnerID: partnerID) = importMail(session: session) else {
//                    XCTFail()
//                    return
//        }
//
//        let meIdent = mySelfID.pEpIdentity()
//        var partnerIdent = partnerID.pEpIdentity()
//        try! session.mySelf(meIdent)
//        try! session.update(partnerIdent)
//
//        // back up the original
//        let partnerIdentOrig = PEPIdentity(identity: partnerIdent)
//        XCTAssertTrue(try! session.isPEPUser(partnerIdentOrig).boolValue)
//
//        try! session.trustPersonalKey(partnerIdent)
//        try! session.update(partnerIdent)
//        XCTAssertTrue(try! session.isPEPUser(partnerIdent).boolValue)
//
//        partnerIdent = PEPIdentity(identity: partnerIdentOrig) // restore backup
//        try! session.keyResetTrust(partnerIdent)
//        try! session.update(partnerIdent)
//        XCTAssertTrue(try! session.isPEPUser(partnerIdent).boolValue)
//
//        partnerIdent = PEPIdentity(identity: partnerIdentOrig) // restore backup
//        try! session.keyMistrusted(partnerIdent)
//        try! session.update(partnerIdent)
//        XCTAssertTrue(try! session.isPEPUser(partnerIdent).boolValue)
//    }
//
//    /**
//     Test trust/reset/mistrust cycle using view model.
//     */
//    func testViewModelTrustMistrustCycles() {
//        let pEpSession = PEPSession()
//
//        guard
//            let (message: _, mySelfID: mySelfID,
//                 partnerID: partnerID) = importMail(session: pEpSession) else {
//                    XCTFail()
//                    return
//        }
//
//        let vm = HandshakePartnerTableViewCellViewModel(ownIdentity: mySelfID, partner: partnerID)
//
//        XCTAssertEqual(vm.partnerRating, .reliable)
//
//        vm.confirmTrust(pEpSession: pEpSession)
//        XCTAssertEqual(vm.partnerRating, .trustedAndAnonymized)
//
//        vm.resetOrUndoTrustOrMistrust(pEpSession: pEpSession)
//        XCTAssertEqual(vm.partnerRating, .reliable)
//
//        vm.denyTrust(pEpSession: pEpSession)
//        XCTAssertEqual(vm.partnerRating, .haveNoKey)
//
//        vm.resetOrUndoTrustOrMistrust(pEpSession: pEpSession)
//        XCTAssertEqual(vm.partnerRating, .reliable)
//
//        vm.confirmTrust(pEpSession: pEpSession)
//        XCTAssertEqual(vm.partnerRating, .trustedAndAnonymized)
//
//        vm.resetOrUndoTrustOrMistrust(pEpSession: pEpSession)
//        XCTAssertEqual(vm.partnerRating, .reliable)
//    }
//
//    /**
//     Test mistrust/reset cycle using view model.
//     */
//    func testViewModelMistrustResetTrustCycle() {
//        let pEpSession = PEPSession()
//
//        guard
//            let (message: _, mySelfID: mySelfID,
//                 partnerID: partnerID) = importMail(session: session) else {
//                    XCTFail()
//                    return
//        }
//
//        let vm = HandshakePartnerTableViewCellViewModel(ownIdentity: mySelfID, partner: partnerID)
//
//        XCTAssertEqual(vm.partnerRating, .reliable)
//
//        vm.denyTrust(pEpSession: pEpSession)
//        XCTAssertEqual(vm.partnerRating, .haveNoKey)
//
//        vm.resetOrUndoTrustOrMistrust(pEpSession: pEpSession)
//        XCTAssertEqual(vm.partnerRating, .reliable)
//
//        vm.confirmTrust(pEpSession: pEpSession)
//        XCTAssertEqual(vm.partnerRating, .trustedAndAnonymized)
//
//        vm.resetOrUndoTrustOrMistrust(pEpSession: pEpSession)
//        XCTAssertEqual(vm.partnerRating, .reliable)
//    }
//}
