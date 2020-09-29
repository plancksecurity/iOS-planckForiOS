//
//  Attachment+clone.swift
//  MessageModel
//
//  Created by Alejandro Gelos on 12/08/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

extension Attachment {

    /// Does *not* clone the message.
    static public func clone(attachmnets: [Attachment], for session: Session) -> [Attachment] {
        var clones = [Attachment]()
        for attachment in attachmnets {
            clones.append(attachment.clone(for: session))
        }
        return clones
    }

    /// Does *not* clone the message.
    public func clone(for session: Session) -> Attachment {
        var image: UIImage? = nil
        var data: Data? = nil
        var mimeType: String? = nil
        var contentDisposition: ContentDispositionType = .attachment
        var fileName: String? = nil
        var assetUrl: URL? = nil
        self.session.moc.performAndWait {
            image = self.image
            data = self.data
            mimeType = self.mimeType
            contentDisposition = self.contentDisposition
            fileName = self.fileName
            assetUrl = self.assetUrl
        }
        var clone = self // Dummy value to vaid Optional
        session.moc.performAndWait {
            clone = Attachment(data: data,
                               mimeType: mimeType ?? MimeTypeUtils.MimesType.defaultMimeType.rawValue,
                               fileName: fileName,
                               image: image,
                               assetUrl: assetUrl,
                               contentDisposition: contentDisposition,
                               session: session)
        }
        return clone
    }
}
