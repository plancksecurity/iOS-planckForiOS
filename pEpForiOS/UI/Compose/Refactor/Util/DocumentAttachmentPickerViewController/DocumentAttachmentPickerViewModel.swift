//
//  DocumentAttachmentPickerViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 24.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol DocumentAttachmentPickerViewModelResultDelegate: class {
    func documentAttachmentPickerViewModel(_ vm: DocumentAttachmentPickerViewModel,
                                           didPick attachment: Attachment)
}

class DocumentAttachmentPickerViewModel {
    lazy private var attachmentFileIOQueue = DispatchQueue(label:
        "security.pep.DocumentAttachmentPickerViewModel.attachmentFileIOQueue",
                                                           qos: .userInitiated)
    weak public var resultDelegate: DocumentAttachmentPickerViewModelResultDelegate?

    public init(resultDelegate: DocumentAttachmentPickerViewModelResultDelegate? = nil) {
        self.resultDelegate = resultDelegate
    }

    public func handleDidPickDocuments(at urls: [URL]) {
        for url in urls {
            createAttachment(forSecurityScopedResource: url) {
                [weak self] (attachment: Attachment?) in
                guard let me = self else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                    return
                }
                guard let safeAttachment = attachment else {
                    Log.shared.errorAndCrash(component: #function,
                                             errorString: "No attachment")
                    return
                }
                GCD.onMain {
                    me.resultDelegate?.documentAttachmentPickerViewModel(me,
                                                                         didPick: safeAttachment)
                }
            }
        }
    }

    /// Used to create an Attachment from security scoped resources.
    /// E.g. Documents provided by UIDocumentPicker
    ///
    /// - Parameters:
    ///   - resourceUrl: URL of the resource to create an attachment for
    /// - Returns: attachment for given resource
    private func createAttachment(forSecurityScopedResource resourceUrl: URL,
                                  completion: @escaping (Attachment?) -> Void) {
        let cfUrl = resourceUrl as CFURL
        attachmentFileIOQueue.async {
            CFURLStartAccessingSecurityScopedResource(cfUrl)
            defer { CFURLStopAccessingSecurityScopedResource(cfUrl) }
            guard  let resourceData = try? Data(contentsOf: resourceUrl)  else {
                Log.shared.errorAndCrash(component: #function, errorString: "No data for URL.")
                completion(nil)
                return
            }
            let mimeType = resourceUrl.mimeType() ?? MimeTypeUtil.defaultMimeType
            let filename = resourceUrl.fileName(includingExtension: true)
            let attachment = Attachment.create(data: resourceData,
                                               mimeType: mimeType,
                                               fileName: filename,
                                               contentDisposition: .attachment)
            completion(attachment)
        }
    }
}
