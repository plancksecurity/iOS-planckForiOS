//
//  ComposeViewModel+Extension.swift
//  pEp
//
//  Created by Martin Brude on 08/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

extension ComposeViewModel {

    /// Get the instance configured with the Mailto object
    /// - Parameter mailTo: The Mailto to configure the Compose View Model.m
    /// - Returns: The ComposeViewModel
    public static func from(mailTo: Mailto?) -> ComposeViewModel {
        func identities(addresses: [String]) -> [Identity]? {
            return addresses.map { return Identity(address: $0) }
        }
        var tos: [Identity]? = nil
        if let mailtos = mailTo?.tos {
            tos = identities(addresses: mailtos)
        }
        var ccs: [Identity]? = nil
        if let mailccs = mailTo?.ccs {
            ccs = identities(addresses: mailccs)
        }
        var bccs: [Identity]? = nil
        if let mailbccs = mailTo?.bccs {
            bccs = identities(addresses: mailbccs)
        }
        var initData = ComposeViewModel.InitData(prefilledTos: tos,
                                                 prefilledCCs: ccs,
                                                 prefilledBCCs: bccs)
        if let body = mailTo?.body {
            initData.bodyPlaintext = body
        } else if let firstTo = mailTo?.tos?.first, firstTo == Constants.supportMail {
            /// To give more precise information to Support, we inform the device and OS version.
            let deviceField = NSLocalizedString("Device", comment: "Device field, reporting issue")
            initData.bodyPlaintext = "\n\n\(deviceField): \(UIDevice().type.rawValue)" + "\n" + "OS: \(UIDevice.current.systemVersion)"
            initData.subject = NSLocalizedString("Help", comment: "Contact Support - Mail subject")
        }

        let state = ComposeViewModel.ComposeViewModelState(initData: initData)
        if let subject = mailTo?.subject {
            state.subject = subject
        }
        return ComposeViewModel(state: state)
    }
}
