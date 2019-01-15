//
//  AttachmentToLocalURLOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 11.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class AttachmentToLocalURLOperation: Operation {
    var fileURL: URL?

    let attachment: Attachment

    init(attachment: Attachment) {
        self.attachment = attachment
    }

    override func main() {
        guard let data = attachment.data else {
            Logger.backendLogger.warn("Attachment without data")
            return
        }
        var tmpDirURL: URL?
        if #available(iOS 10.0, *) {
            tmpDirURL = FileManager.default.temporaryDirectory
        } else {
            tmpDirURL = URL(fileURLWithPath: NSTemporaryDirectory())
        }
        guard let tmpDir = tmpDirURL else {
            return
        }
        let fileName = (attachment.fileName ?? Constants.defaultFileName).extractFileNameOrCid()
        
        var theURL = tmpDir.appendingPathComponent(fileName)

        if attachment.mimeType == "application/pdf" {
            theURL = theURL.appendingPathExtension("pdf")
        }
        do {
            try data.write(to: theURL)
            fileURL = theURL
        } catch {
            Logger.backendLogger.log(error: error)
        }
    }
}
