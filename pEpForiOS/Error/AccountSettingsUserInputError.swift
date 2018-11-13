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
            return NSLocalizedString("Invalid e-mail address: \(message)", comment: "Invalid input for e-mail address")
        case .invalidInputServer(let message):
            return NSLocalizedString("Invalid server: \(message)", comment: "Invalid input for server")
        case .invalidInputPort(let message):
            return NSLocalizedString("Invalid port: \(message)", comment: "Invalid input for por")
        case .invalidInputTransport(let message):
            return NSLocalizedString("Invalid transport security: \(message)", comment: "Invalid input for transport security")
        case .invalidInputAccountName(let message):
            return NSLocalizedString("Invalid account name: \(message)", comment: "Invalid input for account")
        case .invalidInputUserName(let message):
            return NSLocalizedString("Invalid username: \(message)", comment: "Invalid input for username")
        }
    }
}
