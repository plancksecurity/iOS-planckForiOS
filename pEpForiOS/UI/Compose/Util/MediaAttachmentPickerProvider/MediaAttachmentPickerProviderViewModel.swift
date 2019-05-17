//
//  MediaAttachmentPickerViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 19.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel
import pEpIOSToolbox

protocol MediaAttachmentPickerProviderViewModelResultDelegate: class {
    func mediaAttachmentPickerProviderViewModel(_ vm: MediaAttachmentPickerProviderViewModel,
                                                didSelect mediaAttachment:
        MediaAttachmentPickerProviderViewModel.MediaAttachment)

    func mediaAttachmentPickerProviderViewModelDidCancel(
        _ vm: MediaAttachmentPickerProviderViewModel)
}

class MediaAttachmentPickerProviderViewModel {
    lazy private var attachmentFileIOQueue = DispatchQueue(label:
        "security.pep.MediaAttachmentPickerProviderViewModel.attachmentFileIOQueue",
                                                           qos: .userInitiated)
    private var numVideosSelected = 0
    private let mimeTypeUtils = MimeTypeUtils()
    weak public var resultDelegate: MediaAttachmentPickerProviderViewModelResultDelegate?

    public init(resultDelegate: MediaAttachmentPickerProviderViewModelResultDelegate?) {
        self.resultDelegate = resultDelegate
    }

    public func handleDidFinishPickingMedia(info: [UIImagePickerController.InfoKey: Any]) {
        let isImage = (info[UIImagePickerController.InfoKey.originalImage] as? UIImage) != nil
        if isImage {
            // We got an image.
            createImageAttchmentAndInformResultDelegate(info: info)
        } else {
            // We got something from picker that is not an image. Probalby video/movie.
            createMovieAttchmentAndInformResultDelegate(info: info)
        }
    }

    public func handleDidCancel() {
        resultDelegate?.mediaAttachmentPickerProviderViewModelDidCancel(self)
    }

    private func createImageAttchmentAndInformResultDelegate(info: [UIImagePickerController.InfoKey: Any]) {
        guard
            let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage,
            let url = info[UIImagePickerController.InfoKey.referenceURL] as? URL else {
                Log.shared.errorAndCrash("No Data")
                return
        }

        let attachment = createAttachment(forAssetWithUrl: url, image: image)
        let result = MediaAttachment(type: .image, attachment: attachment)
        resultDelegate?.mediaAttachmentPickerProviderViewModel(self, didSelect: result)
    }

    private func createMovieAttchmentAndInformResultDelegate(info: [UIImagePickerController.InfoKey: Any]) {
        guard let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL else {
            Log.shared.errorAndCrash("No URL")
            return
        }

        createAttachment(forResource: url) {[weak self] (attachment)  in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost MySelf")
                return
            }
            guard let att = attachment else {
                Log.shared.errorAndCrash("No Attachment")
                return
            }
            let result = MediaAttachment(type: .movie, attachment: att)
            DispatchQueue.main.async {
                me.resultDelegate?.mediaAttachmentPickerProviderViewModel(me, didSelect: result)
            }
        }
    }

    private func createAttachment(forResource resourceUrl: URL,
                                  completion: @escaping (Attachment?) -> Void) {
        attachmentFileIOQueue.async { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            guard let resourceData = try? Data(contentsOf: resourceUrl) else {
                Log.shared.errorAndCrash("Cound not get data for URL")
                completion(nil)
                return
            }
            let mimeType = me.mimeTypeUtils?.mimeType(fromURL: resourceUrl) ??
                MimeTypeUtils.MimesType.defaultMimeType
            let filename = me.fileName(forVideoAt: resourceUrl)
            let attachment =  Attachment.create(data: resourceData,
                                                mimeType: mimeType,
                                                fileName: filename,
                                                contentDisposition: .attachment)
            completion(attachment)
        }
    }

    private func fileName(forVideoAt url: URL) -> String {
        let fileName = NSLocalizedString("Movie",
                                         comment:
            "File name used for videos the user attaches.")
        numVideosSelected += 1
        let numDisplay = numVideosSelected > 1 ? " " + String(numVideosSelected) : ""
        let fileExtension = url.pathExtension
        return fileName + numDisplay + "." + fileExtension
    }

    private func createAttachment(forAssetWithUrl assetUrl: URL, image: UIImage) -> Attachment {
        let mimeType = mimeTypeUtils?.mimeType(fromURL: assetUrl) ?? MimeTypeUtils.MimesType.defaultMimeType
        return Attachment.createFromAsset(mimeType: mimeType,
                                          assetUrl: assetUrl,
                                          image: image,
                                          contentDisposition: .inline)
    }
}

// MARK: - MediaAttachment

extension MediaAttachmentPickerProviderViewModel {
    struct MediaAttachment {
        enum MediaAttachmentType {
            case image
            case movie
        }
        let type: MediaAttachmentType
        let attachment: Attachment
    }
}
