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

    static private let queue = OperationQueue()

    static func attachmentsURL(inputItems: [NSExtensionItem],
                               completion: @escaping (Result<[URL], Error>)-> Void) {
        var urls = [URL]()
        var operations = [Operation]()

        for item in inputItems {
            guard let attachments = item.attachments else {
                continue
            }

            for attachment in attachments {
                operations.append(BlockOperation() {
                    let group = DispatchGroup()
                    group.enter()
                    attachmentURL(attachment: attachment) { result in
                        switch result {
                        case .failure(let error):
                            queue.cancelAllOperations()
                            completion(.failure(error))
                            group.leave()
                            return
                        case .success(let url):
                            urls.append(url)
                            group.leave()
                        }
                    }
                    group.wait()
                })
            }
        }
        let completionOperation = BlockOperation {
            completion(.success(urls))
        }
        for operation in operations {
            completionOperation.addDependency(operation)
        }
        operations.append(completionOperation)
        queue.addOperations(operations, waitUntilFinished: false)

    }

    static func attachmentURL(attachment: NSItemProvider,
                              completion: @escaping (Result<URL, Error>)-> Void) {
        let attachmentType = type(attachment: attachment)
        guard attachmentType != .other else {
            completion(.failure(ActionExtentionErrors.fileTypeNotSupported))
            return
        }
        let attachmentIdentifier = identifier(type: attachmentType)
        attachment.loadItem(forTypeIdentifier: attachmentIdentifier, options: nil) { (url, error) in
            completion(handleResult(url: url, error: error))
        }
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
            return .failure(ActionExtentionErrors.failToGetAttachmentURL)
        }
        return .success(url)
    }
}
