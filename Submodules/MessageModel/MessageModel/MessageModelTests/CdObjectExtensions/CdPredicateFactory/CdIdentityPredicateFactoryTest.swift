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
        
        let id1 = Identity(address: "no1@no1.com", userName: name1)
        id1.session.commit()
        let id2 = Identity(address: "no2@no2.com", userName: name2)
        id2.session.commit()
        let id3 = Identity(address: "no3@no3.com", userName: name3)
        id3.session.commit()
        let id4 = Identity(address: "no4@no4.com", userName: name4)
        id4.session.commit()
        let id5 = Identity(address: "no5@no5.com", userName: name5)
        id5.session.commit()
        let id6 = Identity(address: "no6@no6.com", userName: name6)
        id6.session.commit()
        let id7 = Identity(address: "no7@no7.com", userName: name7)
        id7.session.commit()
        let id8 = Identity(address: address1, userName: "no8")
        id8.session.commit()
        let id9 = Identity(address: address2, userName: "no9")
        id9.session.commit()
        let id10 = Identity(address: address3, userName: "no10")
        id10.session.commit()
        
        let totalCdIdentities = CdIdentity.all(in: moc)?.count ?? 0
        XCTAssertGreaterThan(totalCdIdentities, 0)
        
        var predicate = CdIdentity.PredicateFactory.recipientSuggestions(for: "pet")
        var result = CdIdentity.all(predicate: predicate, in: moc) as? [CdIdentity] ?? [CdIdentity]()
        XCTAssertTrue(result.contains(id1.cdObject))
        XCTAssertTrue(result.contains(id2.cdObject))
        XCTAssertTrue(result.contains(id3.cdObject))
        XCTAssertTrue(result.contains(id4.cdObject))
        XCTAssertTrue(result.contains(id5.cdObject))
        XCTAssertTrue(result.contains(id6.cdObject))
        XCTAssertFalse(result.contains(id7.cdObject))
        XCTAssertTrue(result.contains(id8.cdObject))
        XCTAssertTrue(result.contains(id9.cdObject))
        XCTAssertTrue(result.contains(id10.cdObject))
        
        predicate = CdIdentity.PredicateFactory.recipientSuggestions(for: "falk")
        result = CdIdentity.all(predicate: predicate, in: moc) as? [CdIdentity] ?? [CdIdentity]()
        XCTAssertTrue(result.contains(id1.cdObject))
        XCTAssertTrue(result.contains(id2.cdObject))
        XCTAssertTrue(result.contains(id3.cdObject))
        XCTAssertTrue(result.contains(id4.cdObject))
        XCTAssertTrue(result.contains(id5.cdObject))
        XCTAssertTrue(result.contains(id6.cdObject))
        XCTAssertFalse(result.contains(id7.cdObject))
        XCTAssertFalse(result.contains(id8.cdObject))
        XCTAssertTrue(result.contains(id9.cdObject))
        XCTAssertTrue(result.contains(id10.cdObject))
        
        predicate = CdIdentity.PredicateFactory.recipientSuggestions(for: "dr.")
        result = CdIdentity.all(predicate: predicate, in: moc) as? [CdIdentity] ?? [CdIdentity]()
        XCTAssertFalse(result.contains(id1.cdObject))
        XCTAssertFalse(result.contains(id2.cdObject))
        XCTAssertTrue(result.contains(id3.cdObject))
        XCTAssertTrue(result.contains(id4.cdObject))
        XCTAssertFalse(result.contains(id5.cdObject))
        XCTAssertFalse(result.contains(id6.cdObject))
        XCTAssertFalse(result.contains(id7.cdObject))
        XCTAssertFalse(result.contains(id8.cdObject))
        XCTAssertFalse(result.contains(id9.cdObject))
        XCTAssertFalse(result.contains(id10.cdObject))
        
        predicate = CdIdentity.PredicateFactory.recipientSuggestions(for: "ter")
        result = CdIdentity.all(predicate: predicate, in: moc) as? [CdIdentity] ?? [CdIdentity]()
        XCTAssertFalse(result.contains(id1.cdObject))
        XCTAssertFalse(result.contains(id2.cdObject))
        XCTAssertFalse(result.contains(id3.cdObject))
        XCTAssertFalse(result.contains(id4.cdObject))
        XCTAssertFalse(result.contains(id5.cdObject))
        XCTAssertFalse(result.contains(id6.cdObject))
        XCTAssertFalse(result.contains(id7.cdObject))
        XCTAssertFalse(result.contains(id8.cdObject))
        XCTAssertFalse(result.contains(id9.cdObject))
        XCTAssertFalse(result.contains(id10.cdObject))
        
        predicate = CdIdentity.PredicateFactory.recipientSuggestions(for: "elm")
        result = CdIdentity.all(predicate: predicate, in: moc) as? [CdIdentity] ?? [CdIdentity]()
        XCTAssertFalse(result.contains(id1.cdObject))
        XCTAssertFalse(result.contains(id2.cdObject))
        XCTAssertFalse(result.contains(id3.cdObject))
        XCTAssertFalse(result.contains(id4.cdObject))
        XCTAssertFalse(result.contains(id5.cdObject))
        XCTAssertFalse(result.contains(id6.cdObject))
        XCTAssertFalse(result.contains(id7.cdObject))
        XCTAssertFalse(result.contains(id8.cdObject))
        XCTAssertFalse(result.contains(id9.cdObject))
        XCTAssertFalse(result.contains(id10.cdObject))
        
        predicate = CdIdentity.PredicateFactory.recipientSuggestions(for: "ans")
        result = CdIdentity.all(predicate: predicate, in: moc) as? [CdIdentity] ?? [CdIdentity]()
        XCTAssertFalse(result.contains(id1.cdObject))
        XCTAssertFalse(result.contains(id2.cdObject))
        XCTAssertFalse(result.contains(id3.cdObject))
        XCTAssertFalse(result.contains(id4.cdObject))
        XCTAssertTrue(result.contains(id5.cdObject))
        XCTAssertTrue(result.contains(id6.cdObject))
        XCTAssertFalse(result.contains(id7.cdObject))
        XCTAssertFalse(result.contains(id8.cdObject))
        XCTAssertFalse(result.contains(id9.cdObject))
        XCTAssertFalse(result.contains(id10.cdObject))
    }
}
