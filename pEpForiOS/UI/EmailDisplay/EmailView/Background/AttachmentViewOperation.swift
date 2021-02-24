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
        case imageAttachment(Attachment, UIImage)
        case docAttachment(Attachment)
    }

    private var attachment: Attachment

    ///The resulting attachment view will appear here.
    private var container: AttachmentContainer?

    /// Constructor
    ///
    /// - Parameters:
    ///   - attachment: The attachment to perform the operation.
    ///   - completionBlock: The completion block. Will be dispatched on main queue. 
    init(attachment: Attachment, completionBlock: @escaping((AttachmentContainer) -> Void)) {
        self.attachment = attachment
        super.init()
        self.completionBlock = { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            guard let container = me.container else {
                Log.shared.errorAndCrash("No container")
                return
            }
            DispatchQueue.main.async {
                completionBlock(container)
            }
        }
    }

    override func main() {
        let mainSession = Session.main
        let safeAttachment = attachment.safeForSession(mainSession)
        mainSession.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
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
