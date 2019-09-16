//
//  MediaAttachmentPickerViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 19.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel
import pEpIOSToolbox
import Photos

protocol MediaAttachmentPickerProviderViewModelResultDelegate: class {

    /// Called when the user finished selecting media content and retruns the MediaAttchement.
    ///
    /// - note: The returned attachment is created on a private Session. No other Session must see
    ///         it unless it has been connected to a message to avoid saving invalid data.
    ///
    /// - Parameters:
    ///   - vm: sender
    ///   - mediaAttachment: attachment for media file selected by the user
    func mediaAttachmentPickerProviderViewModel(_ vm: MediaAttachmentPickerProviderViewModel,
                                                didSelect mediaAttachment:
        MediaAttachmentPickerProviderViewModel.MediaAttachment)

    /// Called when the user decided not to pick any image by clicking `cancel`.
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
        let privateSession = Session()
        var attachment: Attachment!
        privateSession.performAndWait {[weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            attachment = me.createAttachment(forAssetWithUrl: url,
                                             image: image,
                                             session: privateSession)

            if attachment.data == nil {
                do {
                    attachment.data = try Data(contentsOf: url)

                } catch let err {
                    Log.shared.error("%@", "\(err)")
                }
            }
            let group = DispatchGroup()
            var data = attachment.data
            if data == nil {
                let assets = PHAsset.fetchAssets(withALAssetURLs: [url], options: nil)
                if let theAsset = assets.firstObject {
                    group.enter()
                    PHImageManager().requestImageData(for: theAsset, options: nil) {
                        inData, string, orientation, options in
                        data = inData
                        group.leave()
                    }
                }
            }
            group.notify(queue: .main) { [weak self] in
                privateSession.performAndWait {
                    attachment.data = data
                }

                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }
                let result = MediaAttachment(type: .image, attachment: attachment)
                me.resultDelegate?.mediaAttachmentPickerProviderViewModel(me, didSelect: result)
            }
        }
    }

    private func createMovieAttchmentAndInformResultDelegate(info: [UIImagePickerController.InfoKey: Any]) { //BUFF: probably needs private session too
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
            let mimeType = MimeTypeUtils.mimeType(fromURL: resourceUrl)
            let filename = me.fileName(forVideoAt: resourceUrl)
            DispatchQueue.main.async {
                let attachment =  Attachment(data: resourceData,
                                             mimeType: mimeType,
                                             fileName: filename,
                                             contentDisposition: .attachment)
                completion(attachment)
            }
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
                                  image: UIImage,
                                  session: Session) -> Attachment {
        let mimeType = MimeTypeUtils.mimeType(fromURL: assetUrl)
        let privateSession = Session()
        return Attachment.createFromAsset(mimeType: mimeType,
                                          assetUrl: assetUrl,
                                          image: image,
                                          contentDisposition: .inline,
                                          session: session)
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
