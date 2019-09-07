//
//  AttachmentsViewOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

//!!!: rm this file. Make this an extension of Attachment. Accoring to Message+PEPRatingReevaluation.
import Foundation

import MessageModel

class AttachmentsViewOperation: Operation {
    enum AttachmentContainer {
        case imageAttachment(Attachment, UIImage)
        case docAttachment(Attachment)
    }

//    private let session: Session
    private let mimeTypes: MimeTypeUtils?
    private var message: Message

    ///The resulting attachments view will appear here.
    var attachmentContainers = [AttachmentContainer]()

//    /**
//     The number of attachments.
//     */
//    private var attachmentsCount = 0

    init(mimeTypes: MimeTypeUtils?, message: Message) {
//        self.session = message.session

        self.message = message
        self.mimeTypes = mimeTypes
        super.init()

//        session.performAndWait { [weak self] in
//            guard let me = self else {
//                Log.shared.errorAndCrash("Lost myself")
//                return
//            }
//
//            me.attachmentsCount = me.message.viewableAttachments().count
//        }
    }

    override func main() {
        let session = Session()
        session.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }

            let safeMessage = me.message.safeForSession(session)

            let attachments = safeMessage.viewableAttachments()
            for att in attachments {
                if att.isInlined {
                    // Ignore attachments that are already shown inline in the message body.
                    // Try to verify this by checking if their CID (if any) is mentioned there.
                    // So attachments labeled as inline _are_ shown if
                    //  * they don't have a CID
                    //  * their CID doesn't occur in the HTML body
                    var cidContained = false
                    if let theCid = att.fileName?.extractCid() {
                        cidContained = safeMessage.longMessageFormatted?.contains(
                            find: theCid) ?? false
                    }
                    if cidContained {
                        // seems like this inline attachment is really inline, don't show it
                        continue
                    }
                }

                let isImage: Bool
                if let mimeType = att.mimeType {
                    isImage = MimeTypeUtils.isImage(mimeType: mimeType)
                } else {
                    isImage = false
                }
                if (isImage),
                    let imgData = att.data,
                    let img = UIImage.image(gifData: imgData) ?? UIImage(data: imgData) {
                    me.attachmentContainers.append(.imageAttachment(att, img))
                } else {
                    me.attachmentContainers.append(.docAttachment(att))
                }
            }
        }
    }
}
