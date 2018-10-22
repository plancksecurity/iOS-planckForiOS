//
//  MediaAttachmentPickerViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 19.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol MediaAttachmentPickerProviderViewModelResultDelegate: class {
    func mediaAttachmentPickerProviderViewModel(_ vm: MediaAttachmentPickerProviderViewModel,
                                                didSelect mediaAttachment:
        MediaAttachmentPickerProviderViewModel.MediaAttachment)
}

class MediaAttachmentPickerProviderViewModel {
    lazy private var attachmentFileIOQueue = DispatchQueue(label:
        "security.pep.MediaAttachmentPickerProviderViewModel.attachmentFileIOQueue",
                                                           qos: .userInitiated)
    private var numVideosSelected = 0
    weak public var resultDelegate: MediaAttachmentPickerProviderViewModelResultDelegate?

    public init(resultDelegate: MediaAttachmentPickerProviderViewModelResultDelegate?) {
        self.resultDelegate = resultDelegate
    }

    public func handleDidFinishPickingMedia(info: [String: Any]) {
        let isImage = (info[UIImagePickerControllerOriginalImage] as? UIImage) != nil
        if isImage {
            // We got an image.
            createImageAttchmentAndInformResultDelegate(info: info)
        } else {
            // We got something from picker that is not an image. Probalby video/movie.
            createMovieAttchmentAndInformResultDelegate(info: info)
        }
    }

    private func createImageAttchmentAndInformResultDelegate(info: [String: Any]) {
        guard
            let image = info[UIImagePickerControllerOriginalImage] as? UIImage,
            let url = info[UIImagePickerControllerReferenceURL] as? URL else {
                Log.shared.errorAndCrash(component: #function, errorString: "No Data")
                return
        }

        let attachment = createAttachment(forAssetWithUrl: url, image: image)
        let result = MediaAttachment(type: .image, attachment: attachment)
        resultDelegate?.mediaAttachmentPickerProviderViewModel(self, didSelect: result)
    }

    private func createMovieAttchmentAndInformResultDelegate(info: [String: Any]) {
        guard let url = info[UIImagePickerControllerMediaURL] as? URL else {
            Log.shared.errorAndCrash(component: #function, errorString: "No URL")
            return
        }

        createAttachment(forResource: url) {[weak self] (attachment)  in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            guard let att = attachment else {
                Log.shared.errorAndCrash(component: #function, errorString: "No Attachment")
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
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            guard let resourceData = try? Data(contentsOf: resourceUrl) else {
                Log.shared.errorAndCrash(component: #function,
                                         errorString: "Cound not get data for URL")
                completion(nil)
                return
            }
            let mimeType = resourceUrl.mimeType() ?? MimeTypeUtil.defaultMimeType
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

    private func createAttachment(forAssetWithUrl assetUrl: URL,
                                  image: UIImage) -> Attachment {
        let mimeType = assetUrl.mimeType() ?? MimeTypeUtil.defaultMimeType
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
