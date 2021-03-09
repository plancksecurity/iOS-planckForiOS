//
//  EncryptAndSendSharing.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 09.03.21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

import PEPIOSToolboxForAppExtensions

public class EncryptAndSendSharing: EncryptAndSendSharingProtocol {
    public enum SendError: Error {
        case internalError
    }

    // Does nothing, for now, but the compiler insists.
    public init() {
    }

    public func send(message: Message, completion: @escaping (Error?) -> ()) {
        let privateMoc = Stack.shared.newPrivateConcurrentContext
        privateMoc.perform {
            guard let cdMessage = message.cdMessage() else {
                Log.shared.errorAndCrash(message: "Message without corresponding CdMessage")
                completion(SendError.internalError)
                return
            }
            completion(SendError.internalError)
        }
    }
}
