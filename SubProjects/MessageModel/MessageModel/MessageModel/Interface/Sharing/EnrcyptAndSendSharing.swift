//
//  EnrcyptAndSendSharing.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 09.03.21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import Foundation

public class EnrcyptAndSendSharing: EnrcyptAndSendSharingProtocol {
    public enum SendError: Error {
        case notImplemented
    }

    public func send(message: Message, completion: (Error?) -> ()) {
        completion(SendError.notImplemented)
    }
}
