//
//  EncryptAndSendOnce.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 11.03.21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

public class EncryptAndSendOnce: EncryptAndSendOnceProtocol {
    // Does nothing, but keeps the compiler compiling
    public init() {
    }

    public func sendAll() {
    }

    // MARK: Private Member Variables

    private let privateMoc = Stack.shared.newPrivateConcurrentContext
}
