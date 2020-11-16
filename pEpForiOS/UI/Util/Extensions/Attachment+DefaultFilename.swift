//
//  Attachment+DefaultFilename.swift
//  pEp
//
//  Created by Dirk Zimmermann on 04.11.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

extension Attachment {
    static public let defaultFilename = NSLocalizedString("unnamed",
                                                          comment: "file name used for unnamed attachments")
}
