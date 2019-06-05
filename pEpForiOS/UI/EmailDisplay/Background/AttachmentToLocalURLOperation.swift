//
//  AttachmentToLocalURLOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 11.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox
import MessageModel

class AttachmentToLocalURLOperation: Operation {
    var fileURL: URL?

    private let session: Session
    private var safeAttachment: Attachment?

    init(attachment: Attachment) {
        let session = Session()
        self.session = session
        super.init()
        session.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.safeAttachment = attachment.safeForSession(session)
        }
    }

    override func main() {
        session.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            guard let data =  me.safeAttachment?.data else {
                os_log(type: .default, "Attachment without data")
                return
            }
            let tmpDirURL =  FileManager.default.temporaryDirectory
            
            let fileName = ( me.safeAttachment?.fileName ?? Constants.defaultFileName).extractFileNameOrCid()
            var theURL = tmpDirURL.appendingPathComponent(fileName)

            if let mimeType = me.safeAttachment?.mimeType, mimeType == MimeTypeUtils.MimesType.pdf {
                theURL = theURL.appendingPathExtension("pdf")
            }
            do {
                try data.write(to: theURL)
                me.fileURL = theURL
            } catch {
                Log.shared.log(error: error)
            }
        }
    }
}
