//
//  PEPAlertViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Alejandro Gelos on 23/08/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS

class PEPAlertViewModelTest: XCTestCase {

    private var viewModel: PEPAlertViewModel?

    override func setUp() {
        viewModel = PEPAlertViewModel()
    }

    override func tearDown() {
        viewModel = nil
    }

    func testAddAction() {
        // GIVEN
        guard let viewModel = viewModel else {
            XCTFail()
            return
        }
        var actual = State()
        let expected = State(actionsCount: 3)

        // WHEN
        for i in 0...2 {
            let action = PEPUIAlertAction(title: String(i), style: .pEpRed)
            viewModel.add(action: action)
        }
        actual.actionsCount = viewModel.alertActionsCount


        // THEN
        assertExpectations(actual: actual, expected: expected)
    }

    func testHandleButtonEvent() {
        // GIVEN
        guard let viewModel = viewModel else {
            XCTFail()
            return
        }
        var actual = State()
        let expected = State(calledAcctions: [0, 1, 2], actionsCount: 3)

        for i in 0...2 {
            let action = PEPUIAlertAction(title: String(i), style: .pEpRed) { _ in
                actual.calledAcctions.append(i)
            }
            viewModel.add(action: action)
        }
        actual.actionsCount = viewModel.alertActionsCount

        // WHEN
        viewModel.handleButtonEvent(tag: 0)
        viewModel.handleButtonEvent(tag: 1)
        viewModel.handleButtonEvent(tag: 2)

        // THEN
        assertExpectations(actual: actual, expected: expected)
    }
}


extension PEPAlertViewModelTest {
    private func assertExpectations(actual: State, expected: State) {
        XCTAssertEqual(actual.calledAcctions, expected.calledAcctions)
        XCTAssertEqual(actual.actionsCount, expected.actionsCount)

        XCTAssertEqual(actual, expected)
    }
}

// MARK: - State

extension PEPAlertViewModelTest {
    struct State: Equatable {
        var calledAcctions: [Int]
        var actionsCount: Int

        // Default value are default initial state
        init(calledAcctions: [Int] = [Int](),
             actionsCount: Int = 0) {
            self.calledAcctions = calledAcctions
            self.actionsCount = actionsCount
        }
    }
}
