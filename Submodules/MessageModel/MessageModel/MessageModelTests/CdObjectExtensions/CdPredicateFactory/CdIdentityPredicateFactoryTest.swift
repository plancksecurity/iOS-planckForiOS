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

    func testAcceptanceCriteriaOfIOS2257() {
        
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
        
        let id1 = CdIdentity(context: moc)
        id1.address = "no1@no1.com"
        id1.userName = name1
        let id2 = CdIdentity(context: moc)
        id2.address = "no2@no2.com"
        id2.userName = name2
        let id3 = CdIdentity(context: moc)
        id3.address = "no3@no3.com"
        id3.userName = name3
        let id4 = CdIdentity(context: moc)
        id4.address = "no4@no4.com"
        id4.userName = name4
        let id5 = CdIdentity(context: moc)
        id5.address = "no5@no5.com"
        id5.userName = name5
        let id6 = CdIdentity(context: moc)
        id6.address = "no6@no6.com"
        id6.userName = name6
        let id7 = CdIdentity(context: moc)
        id7.address = "no7@no7.com"
        id7.userName = name7
        let id8 = CdIdentity(context: moc)
        id8.address = address1
        id8.userName = "no8"
        let id9 = CdIdentity(context: moc)
        id9.address = address2
        id9.userName = "no9"
        let id10 = CdIdentity(context: moc)
        id10.address = address3
        id10.userName = "no10"
        moc.saveAndLogErrors()
        
        let totalCdIdentities = CdIdentity.all(in: moc)?.count ?? 0
        XCTAssertGreaterThan(totalCdIdentities, 0)
        
        var predicate = CdIdentity.PredicateFactory.recipientSuggestions(for: "pet")
        var result = CdIdentity.all(predicate: predicate, in: moc) as? [CdIdentity] ?? [CdIdentity]()
        XCTAssertTrue(result.contains(id1))
        XCTAssertTrue(result.contains(id2))
        XCTAssertTrue(result.contains(id3))
        XCTAssertTrue(result.contains(id4))
        XCTAssertTrue(result.contains(id5))
        XCTAssertTrue(result.contains(id6))
        XCTAssertFalse(result.contains(id7))
        XCTAssertTrue(result.contains(id8))
        XCTAssertTrue(result.contains(id9))
        XCTAssertTrue(result.contains(id10))
        
        predicate = CdIdentity.PredicateFactory.recipientSuggestions(for: "falk")
        result = CdIdentity.all(predicate: predicate, in: moc) as? [CdIdentity] ?? [CdIdentity]()
        XCTAssertTrue(result.contains(id1))
        XCTAssertTrue(result.contains(id2))
        XCTAssertTrue(result.contains(id3))
        XCTAssertTrue(result.contains(id4))
        XCTAssertTrue(result.contains(id5))
        XCTAssertTrue(result.contains(id6))
        XCTAssertFalse(result.contains(id7))
        XCTAssertFalse(result.contains(id8))
        XCTAssertTrue(result.contains(id9))
        XCTAssertTrue(result.contains(id10))
        
        predicate = CdIdentity.PredicateFactory.recipientSuggestions(for: "dr.")
        result = CdIdentity.all(predicate: predicate, in: moc) as? [CdIdentity] ?? [CdIdentity]()
        XCTAssertFalse(result.contains(id1))
        XCTAssertFalse(result.contains(id2))
        XCTAssertTrue(result.contains(id3))
        XCTAssertTrue(result.contains(id4))
        XCTAssertFalse(result.contains(id5))
        XCTAssertFalse(result.contains(id6))
        XCTAssertFalse(result.contains(id7))
        XCTAssertFalse(result.contains(id8))
        XCTAssertFalse(result.contains(id9))
        XCTAssertFalse(result.contains(id10))
        
        predicate = CdIdentity.PredicateFactory.recipientSuggestions(for: "ter")
        result = CdIdentity.all(predicate: predicate, in: moc) as? [CdIdentity] ?? [CdIdentity]()
        XCTAssertFalse(result.contains(id1))
        XCTAssertFalse(result.contains(id2))
        XCTAssertFalse(result.contains(id3))
        XCTAssertFalse(result.contains(id4))
        XCTAssertFalse(result.contains(id5))
        XCTAssertFalse(result.contains(id6))
        XCTAssertFalse(result.contains(id7))
        XCTAssertFalse(result.contains(id8))
        XCTAssertFalse(result.contains(id9))
        XCTAssertFalse(result.contains(id10))
        
        predicate = CdIdentity.PredicateFactory.recipientSuggestions(for: "elm")
        result = CdIdentity.all(predicate: predicate, in: moc) as? [CdIdentity] ?? [CdIdentity]()
        XCTAssertFalse(result.contains(id1))
        XCTAssertFalse(result.contains(id2))
        XCTAssertFalse(result.contains(id3))
        XCTAssertFalse(result.contains(id4))
        XCTAssertFalse(result.contains(id5))
        XCTAssertFalse(result.contains(id6))
        XCTAssertFalse(result.contains(id7))
        XCTAssertFalse(result.contains(id8))
        XCTAssertFalse(result.contains(id9))
        XCTAssertFalse(result.contains(id10))
        
        predicate = CdIdentity.PredicateFactory.recipientSuggestions(for: "ans")
        result = CdIdentity.all(predicate: predicate, in: moc) as? [CdIdentity] ?? [CdIdentity]()
        XCTAssertFalse(result.contains(id1))
        XCTAssertFalse(result.contains(id2))
        XCTAssertFalse(result.contains(id3))
        XCTAssertFalse(result.contains(id4))
        XCTAssertTrue(result.contains(id5))
        XCTAssertTrue(result.contains(id6))
        XCTAssertFalse(result.contains(id7))
        XCTAssertFalse(result.contains(id8))
        XCTAssertFalse(result.contains(id9))
        XCTAssertFalse(result.contains(id10))
    }
}
