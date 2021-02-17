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
/// Instanciate this operation and set a completion block,  then add it to a queue.
class AttachmentViewOperation: Operation {
    enum AttachmentContainer {
        case imageAttachment(Attachment, UIImage)
        case docAttachment(Attachment)
    }

    private var attachment: Attachment

    ///The resulting attachment view will appear here.
    var container: AttachmentContainer?

    /// Constructor
    ///
    /// - Parameters:
    ///   - attachment: The attachment to perform the operation.
    ///   - completionBlock: The completion block.
    init(attachment: Attachment, completionBlock: @escaping((AttachmentContainer) -> Void)) {
        self.attachment = attachment
        super.init()
        self.completionBlock = { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            if let container = me.container {
                completionBlock(container)
            } else {
                Log.shared.errorAndCrash("Something went wrong, missing container")
            }
        }
    }

    override func main() {
        let session = Session()
        let safeAttachment = attachment.safeForSession(session)

        session.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            guard let message = safeAttachment.message else {
                Log.shared.errorAndCrash("Attachment with no Message")
                return
            }
            let safeMessage = message.safeForSession(session)

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
