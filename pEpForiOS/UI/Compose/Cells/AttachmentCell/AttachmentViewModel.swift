//
//  AttachmentViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

class AttachmentViewModel: CellViewModel {
    /// - note: Before crafting a message to send, this is a dangling Attachment! (message == nil).
    ///         Thus it MUST life on a private Session and MUST NOT be saved.
    let attachment: Attachment
    private lazy var mimeTypeUtils = MimeTypeUtils()

    init(attachment: Attachment) {
        self.attachment = attachment
    }
    public var fileName: String {
        var result: String? = nil
        attachment.session.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            result = me.attachment.fileName
        }
        return result ?? Attachment.defaultFilename
    }

    public var fileExtension: String {
        var result: String? = nil
        attachment.session.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            guard let mimeType = me.attachment.mimeType else {
                Log.shared.errorAndCrash("No MimeType")
                return
            }
            result = me.mimeTypeUtils?.fileExtension(fromMimeType: mimeType)
        }
        return result ?? ""
    }
}
