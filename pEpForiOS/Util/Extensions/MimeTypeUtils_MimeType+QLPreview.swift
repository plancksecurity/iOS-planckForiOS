//
//  MimeTypeUtils_MimeType+QLPreview.swift
//  pEp
//
//  Created by Andreas Buff on 29.09.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import MessageModel

// MARK: - MimeTypeUtils_MimeType+QLPreview

extension MimeTypeUtils.MimeType {

    public var isSupportedByQLPreviewController: Bool {
        return isMicrosoftOfficeMimeType ||
            self == MimeTypeUtils.MimeType.pdf ||
            self == MimeTypeUtils.MimeType.html ||
            self == MimeTypeUtils.MimeType.csv
    }
}
