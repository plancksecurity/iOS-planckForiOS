//
//  EmailListViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Xavier Algarra on 22/08/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//


import XCTest
@testable import pEpForiOS
import MessageModel

class EmailListViewModelTest: CoreDataDrivenTestBase {
    var folder: Folder!
    var EmailListVM : EmailListViewModel!

    fileprivate func setUpViewModel(emailListViewModelTestDelegate: EmailListViewModelTestDelegate) {
        let msgsyncservice = MessageSyncService()
        self.EmailListVM = EmailListViewModel(emailListViewModelDelegate: emailListViewModelTestDelegate, messageSyncService: msgsyncservice, folderToShow: folder)
    }

    /** this set up a view model with one account and one folder saved **/
    override func setUp() {
        super.setUp()

        let acc = cdAccount.account()

        folder = Folder(name: "inbox", parent: nil, account: acc, folderType: .inbox)
        folder.save()

    }

    //delegate bla


    func testViewModelSetUp(){
        assert(expectedUpdateView: true)

    }


    func assert(expectedUpdateView: Bool) {
        var viewModelTestDelegate : EmailListViewModelTestDelegate?

        if expectedUpdateView {
            let updateViewExpectation = expectation(description: "UpdateViewCalled")
            viewModelTestDelegate = EmailListViewModelTestDelegate(expectationUpdateViewCalled: updateViewExpectation)
        }
        guard let vmTestDelegate = viewModelTestDelegate else {
            XCTFail()
            return
        }
        setUpViewModel(emailListViewModelTestDelegate: vmTestDelegate)

        waitForExpectations(timeout: TestUtil.waitTime)
    }

}

class EmailListViewModelTestDelegate: EmailListViewModelDelegate {

    let expectationUpdateViewCalled: XCTestExpectation?

    init(expectationUpdateViewCalled: XCTestExpectation? = nil) {
        self.expectationUpdateViewCalled = expectationUpdateViewCalled
    }

    func emailListViewModel(viewModel: EmailListViewModel, didInsertDataAt indexPaths: [IndexPath]) {
        fatalError()
    }

    func emailListViewModel(viewModel: EmailListViewModel, didUpdateDataAt indexPaths: [IndexPath]) {
        fatalError()
    }

    func emailListViewModel(viewModel: EmailListViewModel, didRemoveDataAt indexPaths: [IndexPath]) {
        fatalError()
    }

    func emailListViewModel(viewModel: EmailListViewModel, didMoveData atIndexPath: IndexPath, toIndexPath: IndexPath) {
        fatalError()
    }

    func emailListViewModel(viewModel: EmailListViewModel, didUpdateUndisplayedMessage message: Message) {
        fatalError()
    }

    func toolbarIs(enabled: Bool) {
        fatalError()
    }

    func showUnflagButton(enabled: Bool) {
        fatalError()
    }

    func showUnreadButton(enabled: Bool) {
        fatalError()
    }

    func updateView() {
        if let expectationUpdateViewCalled = expectationUpdateViewCalled {
            expectationUpdateViewCalled.fulfill()
        }
    }
}
