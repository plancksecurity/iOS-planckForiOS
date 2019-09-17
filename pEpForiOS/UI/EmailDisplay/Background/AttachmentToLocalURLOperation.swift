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

//!!!: must go to MM interfaces. 
class AttachmentToLocalURLOperation: Operation {
    var fileURL: URL?
    private var attachment: Attachment

    init(attachment: Attachment) {
        self.attachment = attachment
        super.init()
    }

    override func main() {
        let session = Session()
        session.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }

            let safeAttachment = me.attachment.safeForSession(session)

            guard let data =  safeAttachment.data else {
                Log.shared.warn("Attachment without data")
                return
            }
            let tmpDirURL =  FileManager.default.temporaryDirectory
            
            let fileName = ( safeAttachment.fileName ?? Constants.defaultFileName).extractFileNameOrCid()
            var theURL = tmpDirURL.appendingPathComponent(fileName)

            if let mimeType = safeAttachment.mimeType, mimeType == MimeTypeUtils.MimesType.pdf {
                theURL = theURL.appendingPathExtension("pdf")
            }
            do {
                try data.write(to: theURL)
                me.fileURL = theURL
            } catch {
                Log.shared.errorAndCrash(error: error)
            }
        }
    }
}
