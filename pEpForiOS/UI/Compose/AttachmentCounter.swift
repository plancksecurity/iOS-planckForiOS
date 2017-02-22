//
//  AttachmentCounter.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 21/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

class AttachmentCounter {
    var attachmentCount = 0

    public func filename(baseName: String, fileExtension: String) -> String {
        let newFileName = String(format: "%@_%03d.%@", baseName, attachmentCount, fileExtension)
        attachmentCount += 1
        return newFileName
    }
}
