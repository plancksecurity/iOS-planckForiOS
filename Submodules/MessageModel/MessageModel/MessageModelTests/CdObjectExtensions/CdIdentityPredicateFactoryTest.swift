//
//  CdIdentityPredicateFactoryTest.swift
//  MessageModelTests
//
//  Created by Xavier Algarra on 29/04/2020.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import XCTest
@testable import MessageModel

class CdIdentityPredicateFactoryTest: PersistentStoreDrivenTestBase {

    func testNewAddressbook() {
        
        let name1 = "Peter Falk"
        let name2 = "Falk Peter"
        let name3 = "Dr. Falk Peter"
        let name4 = "Dr. Peter Falk"
        let name5 = "Falk Anselm Peter"
        let name6 = "Peter Anselm Falk"
        let name7 = "DrPeterAnselmFalk"
        let address1 = "peter@pep.security"
        let address2 = "falk.peter@pep.security"
        let address3 = "falk-peter@pep.security"
        
        let id1 = Identity(address: "no1@no1.com", userName: name1)
        id1.save()
        let id2 = Identity(address: "no2@no2.com", userName: name2)
        id2.save()
        let id3 = Identity(address: "no3@no3.com", userName: name3)
        id3.save()
        let id4 = Identity(address: "no4@no4.com", userName: name4)
        id4.save()
        let id5 = Identity(address: "no5@no5.com", userName: name5)
        id5.save()
        let id6 = Identity(address: "no6@no6.com", userName: name6)
        id6.save()
        let id7 = Identity(address: "no7@no7.com", userName: name7)
        id7.save()
        let id8 = Identity(address: address1, userName: "no8")
        id8.save()
        let id9 = Identity(address: address2, userName: "no9")
        id9.save()
        let id10 = Identity(address: address3, userName: "no10")
        id10.save()
        
        let totalCdIdentities = CdIdentity.all(in: moc)?.count ?? 0
        XCTAssertGreaterThan(totalCdIdentities, 0)
        var predicate = CdIdentity.PredicateFactory.recipientSuggestions(for: "pet")
        var resultCount = CdIdentity.all(predicate: predicate, in: moc)?.count ?? 0
        XCTAssertEqual(resultCount, 9)
        predicate = CdIdentity.PredicateFactory.recipientSuggestions(for: "falk")
        resultCount = CdIdentity.all(predicate: predicate, in: moc)?.count ?? 0
        XCTAssertEqual(resultCount, 8)
        predicate = CdIdentity.PredicateFactory.recipientSuggestions(for: "dr.")
        resultCount = CdIdentity.all(predicate: predicate, in: moc)?.count ?? 0
        XCTAssertEqual(resultCount, 2)
        predicate = CdIdentity.PredicateFactory.recipientSuggestions(for: "ter")
        resultCount = CdIdentity.all(predicate: predicate, in: moc)?.count ?? 0
        XCTAssertEqual(resultCount, 0)
        predicate = CdIdentity.PredicateFactory.recipientSuggestions(for: "elm")
        resultCount = CdIdentity.all(predicate: predicate, in: moc)?.count ?? 0
        XCTAssertEqual(resultCount, 0)
        predicate = CdIdentity.PredicateFactory.recipientSuggestions(for: "ans")
        resultCount = CdIdentity.all(predicate: predicate, in: moc)?.count ?? 0
        XCTAssertEqual(resultCount, 2)
    }
}
