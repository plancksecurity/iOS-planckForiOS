//
//  MoveToAccountViewControllerTest.swift
//  pEpForiOSTests
//
//  Created by Borja González de Pablo on 01/10/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class MoveToFolderViewModelTest: CoreDataDrivenTestBase {
    var messagesToMove =  [Message]()
    var accounts: [Account]!
    var viewmodel: MoveToFolderViewModel!
    var folders = [Folder]()

    override func setUp() {
        super.setUp()
        let account = cdAccount.account()
        givenThereAreTwoFolders()
        viewmodel = MoveToFolderViewModel(account: account, messages: [Message]())
    }

    // MARK: - Move

    func testMessageAreMoved() {
        assertMoved(expDidMoveCalled: true,
                    numMessagesToMove: 10,
                    messageSourceFolder: folders[0],
                    idxMessageTargetFolder: 1,
                    moveMustHappen: true)
    }

    func testNoMessageAreMoved() {
        assertMoved(expDidMoveCalled: false,
                    numMessagesToMove: 0,
                    messageSourceFolder: folders[0],
                    idxMessageTargetFolder: 1,
                    moveMustHappen: false)
    }

    func testInexistentFolderIndexReturnFalse() {
        assertMoved(expDidMoveCalled: false,
                    numMessagesToMove: 10,
                    messageSourceFolder: folders[0],
                    idxMessageTargetFolder: 3,
                    moveMustHappen: false)
    }

    func testMessageAreNotMovedIfTheyBelongToTheDestinationFolder() {
        assertMoved(expDidMoveCalled: false,
                    numMessagesToMove: 10,
                    messageSourceFolder: folders[0],
                    idxMessageTargetFolder: 0,
                    moveMustHappen: false)
    }

    // MARK: - Subscript

    func testSubscriptIsWorking() {
        XCTAssertEqual(viewmodel[0].title,
                       MoveToFolderCellViewModel(folder: folders[0], level: 0).title)
        XCTAssertEqual(viewmodel[1].title,
                       MoveToFolderCellViewModel(folder: folders[1], level: 1).title)
        XCTAssertNotEqual(viewmodel[0].title,
                       MoveToFolderCellViewModel(folder: folders[1], level: 0).title)
    }

    // MARK: - Test Setup Correct

    func testThereAreCorrectItems() {
        XCTAssertEqual(viewmodel.count, folders.count)
    }

    //MARK: - Helper
    
    func givenWeWantToMove(aNumberOfMessages: Int, currentlyInFolder: Folder){
        for i in 0..<aNumberOfMessages {
          let message = TestUtil.createMessage(uid: i, inFolder: currentlyInFolder)
            messagesToMove.append(message)
        }
        viewmodel.messages = messagesToMove
    }

    func givenThereIsAMoveToFolderDelegate(checkCall: Bool) {
        let didMoveExpection =
            expectation(description: MoveToFolderExpectations.DID_MOVE_EXPECTATION_DESCRIPTION)
        if(!checkCall){
            didMoveExpection.isInverted = true
        }
        let delegate = MoveToFolderExpectations(didMoveExpectation: didMoveExpection)
        viewmodel.delegate = delegate
    }

    func givenThereAreTwoFolders() {
        let folder = Folder(name: "inbox", parent: nil, account: account, folderType: .inbox)
        folder.save()
        let trashFolder =
            Folder(name: "trash", parent: nil, account: folder.account, folderType: .trash)
        trashFolder.save()
        folders.append(folder)
        folders.append(trashFolder)
    }

    private func assertMoved(expDidMoveCalled: Bool, numMessagesToMove: Int, messageSourceFolder: Folder, idxMessageTargetFolder: Int, moveMustHappen: Bool) {
        givenThereIsAMoveToFolderDelegate(checkCall: expDidMoveCalled)
        givenWeWantToMove(aNumberOfMessages: numMessagesToMove, currentlyInFolder: messageSourceFolder)

        let moved = viewmodel.moveMessagesTo(index: idxMessageTargetFolder)

        if moveMustHappen {
            XCTAssertTrue(moved)
        } else {
            XCTAssertFalse(moved)
        }
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }
}

//MARK: - MoveToFolderTestDelegate

class MoveToFolderExpectations: MoveToFolderDelegate {
    static let DID_MOVE_EXPECTATION_DESCRIPTION = "DID_MOVE_CALLED"
    var expectationDidMoveCalled: XCTestExpectation?

    public init (didMoveExpectation: XCTestExpectation? = nil) {
        expectationDidMoveCalled = didMoveExpectation
    }

    func didMove() {
        XCTFail()
    }

    func didmove(messages: [Message]) {
        guard let expectation = expectationDidMoveCalled else {
            XCTFail()
            return
        }
        expectation.fulfill()
    }
}
