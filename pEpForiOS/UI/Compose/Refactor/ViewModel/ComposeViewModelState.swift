//
//  ComposeViewModelState.swift
//  pEp
//
//  Created by Andreas Buff on 15.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol ComposeViewModelStateDelegate: class {
    func composeViewModelState(_ composeViewModelState: ComposeViewModelState,
                               didChangeValidationStateTo isValid: Bool)
}
//IOS-1369: wrap in extention when done to not polute the namespace
//extension ComposeViewModel {

/// Wraps bookholding properties
class ComposeViewModelState {
    let initData: InitData?
    private var edited = false
    private var isValidatedForSending = false
    public private(set) var bccWrapped = true

    weak var delegate: ComposeViewModelStateDelegate?

    //Recipients
    var toRecipients = [Identity]() {
        didSet {
            edited = true
            validate()
        }
    }
    var ccRecipients = [Identity]() {
        didSet {
            edited = true
            validate()
        }
    }
    var bccRecipients = [Identity]() {
        didSet {
            edited = true
            validate()
        }
    }

    var from: Identity? {
        didSet {
            edited = true
            validate()
        }
    }

    var subject = "" {
        didSet {
            edited = true
        }
    }

    var body = "" {
        didSet {
            edited = true
        }
    }

    var attachments = [Attachment]() {
        didSet {
            edited = true
        }
    }

    init(initData: InitData? = nil, delegate: ComposeViewModelStateDelegate? = nil) {
        self.initData = initData
        self.delegate = delegate
        setup()
    }

    public func setBccUnwrapped() {
        bccWrapped = true
    }

    private func setup() {
        guard let initData = initData else {
            Log.shared.errorAndCrash(component: #function, errorString: "No data")
            return
        }
        toRecipients = initData.toRecipients
        ccRecipients = initData.ccRecipients
        bccRecipients = initData.bccRecipients
        from = initData.from
        subject = initData.subject ?? " " // Set space to work around autolayout first baseline not recognized
        //            body = initD //IOS-1369: TODO
        attachments = initData.nonInlinedAttachments
    }

    private func validate() {
        //calculateComposeColorAndInstallTapGesture()
        validateForSending()
    }

    private func validateForSending() {
        let before = isValidatedForSending
        //IOS-1369: unimplemented stub") //IOS-1369:
        //TODO: validate!
        //atLeastOneRecipientIsSet && !hasInvalidRecipients && from != nil
        isValidatedForSending = !isValidatedForSending
        if before != isValidatedForSending {
            delegate?.composeViewModelState(self,
                                            didChangeValidationStateTo: isValidatedForSending)
        }
    }
}
//}
