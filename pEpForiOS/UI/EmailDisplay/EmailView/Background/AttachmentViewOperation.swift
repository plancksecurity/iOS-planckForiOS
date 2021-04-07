//
//  AttachmentViewOperation.swift
//  pEpForiOS
//
//  Created by Martín Brude on 17/2/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import pEpIOSToolbox

/// Operation to get the Attachments view.
/// Loads all attachments of the given message from disk and creates AttachmentContainers for it
class AttachmentViewOperation: Operation {

    enum AttachmentContainer {
        case imageAttachment(attachment: Attachment, image: UIImage)
        case docAttachment(attachment: Attachment)
    }

    private var attachment: Attachment

    ///The resulting attachment view will appear here.
    private var container: AttachmentContainer?

    /// Constructor
    ///
    /// - Parameters:
    ///   - attachment: The attachment to perform the operation for.
    ///   - completionBlock: The completion block. Will be dispatched on main queue. 
    init(attachment: Attachment,
         completionBlock: @escaping((AttachmentContainer?) -> Void)) {
        self.attachment = attachment
        super.init()
        self.completionBlock = { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            defer {
                DispatchQueue.main.async { completionBlock(me.container) }
            }
            guard let _ = me.container else {
                Log.shared.errorAndCrash("No container. Looks like we failed.")
                return
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
            var isImage: Bool = false
            if let mimeType = safeAttachment.mimeType {
                isImage = MimeTypeUtils.isImage(mimeType: mimeType)
            }
            if isImage {
                guard let imageData = safeAttachment.data,
                      let image = UIImage.image(gifData: imageData) ?? UIImage(data: imageData)
                else {
                    Log.shared.errorAndCrash("No image!")
                    return
                }
                // We intentionally do _not_ use safeAttachment here but the one passed by the client.
                me.container = .imageAttachment(attachment: me.attachment, image: image)
            } else {
                // We intentionally do _not_ use safeAttachment here but the one passed by the client.
                me.container = .docAttachment(attachment: me.attachment)
            }
        }
    }
}
