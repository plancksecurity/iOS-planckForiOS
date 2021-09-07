//
//  MediaAttachmentPickerViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 19.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Photos
import UIKit

#if EXT_SHARE
import MessageModelForAppExtensions
import pEpIOSToolboxForExtensions
#else
import MessageModel
import pEpIOSToolbox
#endif

protocol MediaAttachmentPickerProviderViewModelResultDelegate: AnyObject {

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
    let session: Session
    weak public var resultDelegate: MediaAttachmentPickerProviderViewModelResultDelegate?

    public init(resultDelegate: MediaAttachmentPickerProviderViewModelResultDelegate?,
                session: Session) {
        self.resultDelegate = resultDelegate
        self.session = session
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

    /// Handle the image selection
    /// - Parameters:
    ///   - url: The url of the image
    ///   - image: The image itself
    public func handleDidFinishPickingImage(url: URL, image: UIImage) {
        createImageAttchmentAndInformResultDelegate(url: url, image: image)
    }

    /// Handle the video selection
    /// - Parameter url: The url of the resource
    public func handleDidFinishPickingVideoAt(url: URL) {
        // We got something from picker that is not an image. Probalby video/movie.
        createMovieAttchmentAndInformResultDelegate(url: url)
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

//MARK: - Private

extension MediaAttachmentPickerProviderViewModel {

    //MARK: -  iOS version greater than iOS14

    private func createMovieAttchmentAndInformResultDelegate(url: URL) {
        createAttachment(forResource: url, session: session) {[weak self] (attachment)  in
            guard let me = self else {
                // Valid case. We might have been dismissed already.
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

    private func createImageAttchmentAndInformResultDelegate(url: URL, image: UIImage) {
        var attachment: Attachment!
        session.performAndWait {[weak self] in
            guard let me = self else {
                // Valid case. We might have been dismissed already.
                return
            }
            attachment = me.createAttachment(forAssetWithUrl: url, image: image, session: me.session)
            if attachment.data == nil {
                do {
                    attachment.data = try Data(contentsOf: url)
                } catch let err {
                    Log.shared.error("%@", "\(err)")
                }
            }
            let group = DispatchGroup()
            let data = attachment.data
            group.notify(queue: .main) { [weak self] in
                guard let me = self else {
                    // Valid case. We might have been dismissed.
                    return
                }
                me.session.performAndWait {
                    attachment.data = data
                }
                let result = MediaAttachment(type: .image, attachment: attachment)
                DispatchQueue.main.async {
                    me.resultDelegate?.mediaAttachmentPickerProviderViewModel(me, didSelect: result)
                }
            }
        }
    }

    //MARK: -  iOS version lower than iOS14

    private func createImageAttchmentAndInformResultDelegate(info: [UIImagePickerController.InfoKey: Any]) {
        guard
            let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage,
            let url = info[UIImagePickerController.InfoKey.referenceURL] as? URL else {
                Log.shared.errorAndCrash("No Data")
                return
        }
        var attachment: Attachment!
        session.performAndWait {[weak self] in
            guard let me = self else {
                // Valid case. We might have been dismissed already.
                return
            }
            attachment = me.createAttachment(forAssetWithUrl: url,
                                             image: image,
                                             session: me.session)

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
                guard let me = self else {
                    // Valid case. We might have been dismissed.
                    return
                }
                me.session.performAndWait {
                    attachment.data = data
                }

                let result = MediaAttachment(type: .image, attachment: attachment)
                me.resultDelegate?.mediaAttachmentPickerProviderViewModel(me, didSelect: result)
            }
        }
    }

    private func createMovieAttchmentAndInformResultDelegate(info: [UIImagePickerController.InfoKey: Any]) {
        guard let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL else {
            Log.shared.errorAndCrash("No URL")
            return
        }
        createAttachment(forResource: url, session: session) {[weak self] (attachment)  in
            guard let me = self else {
                // Valid case. We might have been dismissed already.
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
                                  session: Session,
                                  completion: @escaping (Attachment?) -> Void) {
        attachmentFileIOQueue.async { [weak self] in
            guard let me = self else {
                // Valid case. We might have been dismissed already.
                return
            }
            guard let resourceData = try? Data(contentsOf: resourceUrl) else {
                Log.shared.errorAndCrash("Cound not get data for URL")
                completion(nil)
                return
            }
            let mimeType = MimeTypeUtils.mimeType(fromURL: resourceUrl)
            let filename = me.fileName(forVideoAt: resourceUrl)
            session.perform {
                let attachment = Attachment(data: resourceData,
                                            mimeType: mimeType,
                                            fileName: filename,
                                            contentDisposition: .attachment,
                                            session: session)
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
        return Attachment.createFromAsset(mimeType: mimeType,
                                          assetUrl: assetUrl,
                                          image: image,
                                          contentDisposition: .inline,
                                          session: session)
    }
}
