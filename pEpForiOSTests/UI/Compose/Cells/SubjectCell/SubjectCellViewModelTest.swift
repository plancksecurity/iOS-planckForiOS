//
//  SubjectCellViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 12.11.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
import MessageModel

class SubjectCellViewModelTest: XCTestCase {

    // MARK: - Helper



}

class TestSubjectCellViewModelResultDelegate: SubjectCellViewModelResultDelegate {
    let expDidChangeSubjectCalled: XCTestExpectation?
    let expectedSubject: String?

    init(expDidChangeSubjectCalled: XCTestExpectation?, expectedSubject: String?)  {
        self.expDidChangeSubjectCalled = expDidChangeSubjectCalled
        self.expectedSubject = expectedSubject
    }

    func subjectCellViewModelDidChangeSubject(_ vm: SubjectCellViewModel) {
        guard let exp = expDidChangeSubjectCalled else {
            // We ignore called or not
            return
        }
        exp.fulfill()
        if let expected = expectedSubject {
            XCTAssertEqual(vm.content, expected)
        }
    }
}
