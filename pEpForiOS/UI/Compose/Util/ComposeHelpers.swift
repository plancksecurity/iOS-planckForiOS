//
//  ComposeHelpers.swift
//  pEpForiOS
//
//  Created by Yves Landert on 04.11.16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import UIKit
import MessageModel

struct ComposeHelpers {
    static fileprivate let defaultFilenameLength = 20
}

extension String {
    static let textAttachmentCharacter: UInt32 = 65532

    var cleanAttachments: String {
        if let uc = UnicodeScalar(String.textAttachmentCharacter) {
            let s = String(Character(uc))
            return self.replacingOccurrences(of: s, with: "").trimmed()
        }
        return self
    }

    var isAttachment: Bool {
        guard self.count == 1 else {
            return false
        }
        if let ch = self.unicodeScalars.first {
            return ch.value == String.textAttachmentCharacter
        }
        return false
    }

    var truncate: String {
        let length = self.count
        if length > ComposeHelpers.defaultFilenameLength {
            let index: String.Index = self.index(self.startIndex,
                                                 offsetBy: ComposeHelpers.defaultFilenameLength)
            return String(prefix(upTo: index))
        }
        return self
    }
}
