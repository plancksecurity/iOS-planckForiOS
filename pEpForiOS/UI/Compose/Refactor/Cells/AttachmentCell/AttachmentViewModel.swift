//
//  AttachmentViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

class AttachmentViewModel: CellViewModel {
    //    static let preferredHigh: CGFloat = 114.0 //IOS-1369: from cell
    public var fileName: String {
        return attachment.fileName ?? NSLocalizedString("unknown",
                                                        comment:
            "Displayed attachment filename if unknown")
    }
    public var fileExtension: String {
        return mimeTypeUtil?.fileExtension(mimeType: attachment.mimeType) ?? ""
    }

    private let attachment: Attachment
    private let mimeTypeUtil = MimeTypeUtil()

    init(attachment: Attachment) {
        self.attachment = attachment
    }
}
