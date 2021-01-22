//
//  CdImapFields+TestHelper.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 22/03/2017.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//

@testable import MessageModel

extension CdImapFields {
    func flagsFromServerBoolsEqual(flagBits: ImapFlagsBits?) -> Bool {
        guard let theServerFlags = serverFlags else {
            if let theBits = flagBits {
                return theBits.isEmpty()
            } else {
                return true
            }
        }
        return theServerFlags.flagsEqual(flagBits: flagBits)
    }
}
