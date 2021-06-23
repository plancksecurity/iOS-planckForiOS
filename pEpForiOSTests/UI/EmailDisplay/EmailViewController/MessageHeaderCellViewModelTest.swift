//
//  MessageHeaderCellViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Martín Brude on 21/5/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS
@testable import MessageModel
import pEpIOSToolbox

class MessageHeaderCellViewModelTest: XCTestCase {

    private var vm: MessageHeaderCellViewModel!
    private var delegateMock = EmailViewController()
    override func setUp() {
        super.setUp()
        let identity = Identity(address: "mb@pep.security")
        vm = MessageHeaderCellViewModel(displayedImageIdentity: identity)
    }

    func testCollectionViewViewModelsAreNilWithoutSetup() {
        XCTAssertNil(vm.fromCollectionViewViewModel)
        XCTAssertNil(vm.tosCollectionViewViewModel)
        XCTAssertNil(vm.ccsCollectionViewViewModel)
        XCTAssertNil(vm.bccsCollectionViewViewModel)
    }

    func testCollectionViewViewModelsAreNotNilAfterSetup() {
        let fromIdentity = Identity(address: "mb@pep.security")
        let toIdentity = Identity(address: "mb@pep.security")
        let ccIdentity = Identity(address: "mb@pep.security")
        let bccIdentity = Identity(address: "mb@pep.security")

        let fromCollectionViewVM = EmailViewModel.CollectionViewCellViewModel(identity: fromIdentity, recipientType: .from)
        let tosCollectionViewVM = [EmailViewModel.CollectionViewCellViewModel(identity: toIdentity, recipientType: .to)]
        let ccsCollectionViewVM = [EmailViewModel.CollectionViewCellViewModel(identity: ccIdentity, recipientType: .cc)]
        let bccsCollectionViewVM = [EmailViewModel.CollectionViewCellViewModel(identity: bccIdentity, recipientType: .bcc)]

        vm.setup(shouldDisplayAll: [EmailViewModel.RecipientType.to: true,
                                    EmailViewModel.RecipientType.cc: true,
                                    EmailViewModel.RecipientType.bcc: true],
                 recipientsContainerWidth: 1.0,
                 fromContainerWidth: 1.0,
                 fromViewModel: fromCollectionViewVM,
                 toViewModels: tosCollectionViewVM,
                 ccViewModels: ccsCollectionViewVM,
                 bccViewModels: bccsCollectionViewVM,
                 delegate: delegateMock)

        XCTAssertNotNil(vm.fromCollectionViewViewModel)
        XCTAssertNotNil(vm.tosCollectionViewViewModel)
        XCTAssertNotNil(vm.ccsCollectionViewViewModel)
        XCTAssertNotNil(vm.bccsCollectionViewViewModel)
    }
}
