//
//  AttachmentsViewOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class AttachmentsViewOperation: Operation {
    enum AttachmentContainer {
        case imageAttachment(Attachment, UIImage)
        case docAttachment(Attachment)
    }

    private let session: Session
    private let mimeTypes: MimeTypeUtils?
    public var message: Message

    /**
     The resulting attachments view will appear here.
     */
    var attachmentContainers = [AttachmentContainer]()

    /**
     The number of attachments.
     */
    private var attachmentsCount = 0

    init(mimeTypes: MimeTypeUtils?, message: Message) {
        let session = Session()
        self.session = session
        self.message = message.safeForSession(session)

        self.mimeTypes = mimeTypes
        super.init()

        session.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }

            me.attachmentsCount = me.message.viewableAttachments().count
        }
    }

    override func main() {
        session.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }

            let attachments = me.message.viewableAttachments()
            for att in attachments {
                if att.isInlined {
                    // Ignore attachments that are already shown inline in the message body.
                    // Try to verify this by checking if their CID (if any) is mentioned there.
                    // So attachments labeled as inline _are_ shown if
                    //  * they don't have a CID
                    //  * their CID doesn't occur in the HTML body
                    var cidContained = false
                    if let theCid = att.fileName?.extractCid() {
                        cidContained = me.message.longMessageFormatted?.contains(
                            find: theCid) ?? false
                    }
                    if cidContained {
                        // seems like this inline attachment is really inline, don't show it
                        continue
                    }
                }

                let isImage: Bool
                if let mimeType = att.mimeType {
                    isImage = me.mimeTypes?.isImage(mimeType: mimeType) ?? false
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
