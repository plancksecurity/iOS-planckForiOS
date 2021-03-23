//
//  DocumentAttachmentPickerViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 24.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

protocol DocumentAttachmentPickerViewModelResultDelegate: class {
    func documentAttachmentPickerViewModel(_ vm: DocumentAttachmentPickerViewModel,
                                           didPick attachment: Attachment)

    func documentAttachmentPickerViewModelDidCancel(_ vm: DocumentAttachmentPickerViewModel)
}

class DocumentAttachmentPickerViewModel {
    lazy private var attachmentFileIOQueue = DispatchQueue(label:
        "security.pep.DocumentAttachmentPickerViewModel.attachmentFileIOQueue", qos: .userInitiated)
    private let session: Session
    weak public var resultDelegate: DocumentAttachmentPickerViewModelResultDelegate?

    public init(resultDelegate: DocumentAttachmentPickerViewModelResultDelegate? = nil,
                session: Session) {
        self.resultDelegate = resultDelegate
        self.session = session
    }

    public func handleDidPickDocuments(at urls: [URL]) {
        for url in urls {
            createAttachment(forSecurityScopedResource: url) {
                [weak self] (attachment: Attachment?) in
                guard let me = self else {
                    // Valid case. We might have been dismissed already.
                    return
                }
                guard let safeAttachment = attachment else {
                    Log.shared.errorAndCrash("No attachment")
                    return
                }
                GCD.onMain {
                    me.resultDelegate?.documentAttachmentPickerViewModel(me,
                                                                         didPick: safeAttachment)
                }
            }
        }
    }

    public func handleDidCancel() {
        resultDelegate?.documentAttachmentPickerViewModelDidCancel(self)
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
        attachmentFileIOQueue.async { [weak self] in
            guard let me = self else {
                // Valid case. We might have been dismissed already.
                return
            }
            CFURLStartAccessingSecurityScopedResource(cfUrl)
            defer { CFURLStopAccessingSecurityScopedResource(cfUrl) }
            guard  let resourceData = try? Data(contentsOf: resourceUrl)  else {
                Log.shared.errorAndCrash("No data for URL.")
                completion(nil)
                return
            }
            let mimeType = MimeTypeUtils.mimeType(fromURL: resourceUrl)
            let filename = resourceUrl.fileName(includingExtension: true)

            me.session.performAndWait {
                let attachment = Attachment(data: resourceData,
                                            mimeType: mimeType,
                                            fileName: filename,
                                            contentDisposition: .attachment,
                                            session: me.session)
                completion(attachment)
            }
        }
    }
}
