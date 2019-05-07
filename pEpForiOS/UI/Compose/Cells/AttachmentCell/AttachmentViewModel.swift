//
//  AttachmentViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

class AttachmentViewModel: CellViewModel {
    public let attachment: Attachment
    private let mimeTypeUtil = MimeTypeUtil()

    init(attachment: Attachment) {
        self.attachment = attachment
    }

    static let defaultFileName = NSLocalizedString("unknown",
                                                   comment:
        "Displayed attachment filename if unknown")
    public var fileName: String {
        return attachment.fileName ?? AttachmentViewModel.defaultFileName
    }

    public var fileExtension: String {
        return mimeTypeUtil?.fileExtension(mimeType: attachment.mimeType) ?? ""
    }
}
