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
        guard let mailTo = mailTo else {
            return ComposeViewModel()
        }
        var initData = ComposeViewModel.InitData(mailto: mailTo)
        if let firstTo = mailTo.tos?.first, firstTo.address == Constants.supportMail {
            /// To give more precise information to Support, we inform the device and OS version.
            let deviceField = NSLocalizedString("Device", comment: "Device field, reporting issue")
            initData.bodyPlaintext = "\n\n\(deviceField): \(UIDevice().type.rawValue)" + "\n" + "OS: \(UIDevice.current.systemVersion)"
            initData.subject = NSLocalizedString("Help", comment: "Contact Support - Mail subject")
        }
        let state = ComposeViewModelState(initData: initData)
        return ComposeViewModel(state: state)
    }
}
