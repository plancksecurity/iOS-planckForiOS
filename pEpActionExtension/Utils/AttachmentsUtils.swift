//
//  AttachmentsUtils.swift
//  pEpActionExtension
//
//  Created by Alejandro Gelos on 11/06/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import  MobileCoreServices

struct AttachmentsUtils {
    enum AttachmentType {
        case image, file, text, other
    }

    static func attachmentURL(attachment: NSItemProvider,
                              completion: @escaping (Result<URL, Error>)-> Void) {
        let attachmentType = type(attachment: attachment)
        guard attachmentType != .other else {
            return
        }
        var attachmentIdentifier = identifier(type: attachmentType)
        attachment.loadItem(forTypeIdentifier: attachmentIdentifier, options: nil,
                                                completionHandler: { (url, error) in
            completion(handleResult(url: url, error: error))
        })
    }
}

// MARK: - Private
extension AttachmentsUtils {
    static private func type(attachment: NSItemProvider) -> AttachmentType {
        if attachment.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
            return .image
        }
        if attachment.hasItemConformingToTypeIdentifier(kUTTypeFileURL as String) {
            return .file
        }
        if attachment.hasItemConformingToTypeIdentifier(kUTTypeText as String) {
            return .text
        }
        return .other
    }

    static private func identifier(type: AttachmentType) -> String {
        switch type {
        case .image:
            return (kUTTypeImage as String)
        case .file:
            return (kUTTypeFileURL as String)
        case .text:
            return (kUTTypeText as String)
        case .other:
            return String()
        }
    }

    static private func handleResult(url: NSSecureCoding?, error: Error?) -> Result<URL, Error> {
        if let error = error {
            return .failure(error)
        }
        guard let url = url as? URL else {
            return .failure(ActionExtentionErrors.failToShareNoNSExtensionItem)
        }
        return .success(url)
    }
}
