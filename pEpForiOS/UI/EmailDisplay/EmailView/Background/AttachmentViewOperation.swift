//
//  AttachmentsViewOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import pEpIOSToolbox

/// Operation to get the Attachments view.
/// Instanciate this operation, set a completion block,  add it to a queue.
///
///   let attachmentViewOperation = AttachmentViewOperation(attachment: attachment)
///  attachmentViewOperation.completionBlock = {
///    DispatchQueue.main.async {
///        prepareAttachmentRow(attachmentViewOperation: attachmentViewOperation, completion: completion)
///    }
/// }
/// operationQueue.addOperation(attachmentViewOperation)

class AttachmentViewOperation: Operation {
    enum AttachmentContainer {
        case imageAttachment(Attachment, UIImage)
        case docAttachment(Attachment)
    }

    private var attachment: Attachment

    ///The resulting attachment view will appear here.
    var container: AttachmentContainer?

    /// Constructor
    /// - Parameter attachment: The attachment
    init(attachment: Attachment, completionBlock: (() -> Void)?) {
        self.attachment = attachment
        self.completionBlock = completionBlock
        super.init()
    }

    override func main() {
        let session = Session()
        guard let message = attachment.message else {
            Log.shared.errorAndCrash("Attachment with no Message")
            return
        }
        let safeMessage = message.safeForSession(session)
        let safeAttachment = attachment.safeForSession(session)

        session.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            // Ignore attachments that are already shown inline in the message body.
            // Try to verify this by checking if their CID (if any) is mentioned there.
            // So attachments labeled as inline _are_ shown if
            //  * they don't have a CID
            //  * their CID doesn't occur in the HTML body
            var cidContained = false
            if let theCid = safeAttachment.fileName?.extractCid() {
                cidContained = safeMessage.longMessageFormatted?.contains(
                    find: theCid) ?? false
            }
            if cidContained {
                // seems like this inline attachment is really inline, don't show it
                return
            }

            var isImage: Bool = false
            if let mimeType = safeAttachment.mimeType {
                isImage = MimeTypeUtils.isImage(mimeType: mimeType)
            }
            if isImage, let imageData = safeAttachment.data,
               let image = UIImage.image(gifData: imageData) ?? UIImage(data: imageData) {
                me.container = .imageAttachment(safeAttachment, image)
            } else {
                me.container = .docAttachment(safeAttachment)
            }
        }
    }
}
