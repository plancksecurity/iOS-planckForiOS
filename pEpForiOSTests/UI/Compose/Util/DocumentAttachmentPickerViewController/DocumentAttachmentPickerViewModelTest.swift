//
//  DocumentAttachmentPickerViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 24.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
import MessageModel

class DocumentAttachmentPickerViewModelTest: XCTestCase {

    func testInit() {
        let testee = DocumentAttachmentPickerViewModel()
        XCTAssertNotNil(testee)
    }

    // Impossible to test more due to not having access to SecurityScopedResources (documents).
}
