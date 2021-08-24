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
    case invalidInputServerPassword(localizedMessage:String)
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
                    "Invalid email address: %1$@",
                    comment: "Invalid input for email address"), message)
        case .invalidInputServer(let message):
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "Invalid server: %1$@", comment: "Invalid input for server"),
                message)
        case .invalidInputPort(let message):
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "Invalid port: %1$@", comment: "Invalid input for por"),
                message)
        case .invalidInputTransport(let message):
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "Invalid transport security: %1$@",
                    comment: "Invalid input for transport security"),
                message)
        case .invalidInputAccountName(let message):
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "Invalid account name: %1$@",
                    comment: "Invalid input for account"),
                message)
        case .invalidInputUserName(let message):
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "Invalid username: %1$@",
                    comment: "Invalid input for username"),
                message)
        case .invalidInputServerPassword(let message):
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "Invalid server: %1$@", comment: "Invalid input for server"),
                message)
        }
    }
}
