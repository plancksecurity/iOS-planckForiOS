//
//  Attachment+LocalURL.swift
//  MessageModel
//
//  Created by Andreas Buff on 06.03.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

/// Saves a gien attachment to the /tmp dir.
/// Some iOS SDK calls require a URL (e.g. showing a PDF with QLPreviewController)

// MARK: - Attachment+LocalURL

extension Attachment {

    static public let defaultFileName = NSLocalizedString("unnamed",
                                                   comment: "file name used for unnamed attachments")

    /// Saves  the attachment to the /tmp dir and returns the file URL when done.
    /// Some iOS SDK calls require a URL (e.g. showing a PDF with QLPreviewController).
    /// - Parameter completion: called when done, passes the local URL if writing to /tmp dir succeded, passes `nil`otherwize
    public func saveToTmpDirectory(completion: @escaping (URL?)->Void) {
        let session = Session()
        let safeAttachment = safeForSession(session)
        DispatchQueue.global(qos: .userInitiated).async {
            session.performAndWait {
                var resultUrl: URL? = nil
                defer { completion(resultUrl) }
                guard let data =  safeAttachment.data else {
                    // I do not see this as a valid case in our current implementation.
                    // I actually think it is wrong that `data` is optional in CdAttachment.
                    Log.shared.errorAndCrash("No data")
                    return
                }
                let tmpDir =  FileManager.default.temporaryDirectory

                let fileName = ( safeAttachment.fileName ?? Attachment.defaultFileName).extractFileNameOrCid()
                var url = tmpDir.appendingPathComponent(fileName)

                if let mimeType = safeAttachment.mimeType, mimeType == MimeTypeUtils.MimeType.pdf.rawValue {
                    url = url.appendingPathExtension("pdf")
                }
                do {
                    try data.write(to: url)
                    resultUrl = url
                } catch {
                    Log.shared.errorAndCrash(error: error)
                }
            }
        }
    }
}
