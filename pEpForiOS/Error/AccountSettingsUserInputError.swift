//
//  AccountSettingsUserInputError.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 03.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

public enum AccountSettingsUserInputError: Error {
    case invalidInputEmailAddress(localizedMessage:String)
    case invalidInputServer(localizedMessage:String)
    case invalidInputPort(localizedMessage:String)
    case invalidInputTransport(localizedMessage:String)
    case invalidInputAccountName(localizedMessage:String)
    case invalidInputUserName(localizedMessage:String)
}

extension AccountSettingsUserInputError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidInputEmailAddress(let message):
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "Invalid e-mail address: %@",
                    comment: "Invalid input for e-mail address"), message)
        case .invalidInputServer(let message):
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "Invalid server: %@", comment: "Invalid input for server"),
                message)
        case .invalidInputPort(let message):
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "Invalid port: %@", comment: "Invalid input for por"),
                message)
        case .invalidInputTransport(let message):
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "Invalid transport security: %@",
                    comment: "Invalid input for transport security"),
                message)
        case .invalidInputAccountName(let message):
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "Invalid account name: %@",
                    comment: "Invalid input for account"),
                message)
        case .invalidInputUserName(let message):
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "Invalid username: %@",
                    comment: "Invalid input for username"),
                message)
        }
    }
}
