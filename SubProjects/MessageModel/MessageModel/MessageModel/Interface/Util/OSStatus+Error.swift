//
//  OSStatus+Error.swift
//  MessageModel
//
//  Created by Martín Brude on 26/1/21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import Foundation

extension OSStatus {

    public var error: NSError? {
        guard self != errSecSuccess else { return nil }
        let message = SecCopyErrorMessageString(self, nil) as String? ?? "Unknown error"
        return NSError(domain: NSOSStatusErrorDomain, code: Int(self), userInfo: [
            NSLocalizedDescriptionKey: message])
    }
}

