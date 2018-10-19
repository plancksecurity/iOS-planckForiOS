//
//  MediaAttachmentPickerProvider.swift
//  pEp
//
//  Created by Andreas Buff on 19.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class MediaAttachmentPickerProvider: NSObject {
    public private(set) var imagePicker = UIImagePickerController()

    public var viewModel: MediaAttachmentPickerProviderViewModel?

    // MARK: - Setup

    init(with viewModel: MediaAttachmentPickerProviderViewModel) {
        self.viewModel = viewModel
        super.init()
        setup()
//        navigationDelegate = self//IOS-1369: YAGNI?
    }

    private func setup() {
        imagePicker.delegate = self
        if let mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) {
            imagePicker.mediaTypes = mediaTypes
        }
    }


    /*
     // MARK: - Attachments

     /// Used to create an Attachment from images provided by UIImagePicker
     ///
     /// - Parameters:
     ///   - assetUrl: URL of the asset
     ///   - image: image to create attachment for
     /// - Returns: attachment for given image
     private final func createAttachment(forAssetWithUrl assetUrl: URL,
     image: UIImage) -> Attachment {
     let mimeType = assetUrl.mimeType() ?? MimeTypeUtil.defaultMimeType
     return Attachment.createFromAsset(mimeType: mimeType,
     assetUrl: assetUrl,
     image: image,
     contentDisposition: .inline)
     }
     */
}

// MARK: - UIImagePickerControllerDelegate

extension MediaAttachmentPickerProvider: UIImagePickerControllerDelegate {

    public func imagePickerController( _ picker: UIImagePickerController,
                                       didFinishPickingMediaWithInfo info: [String: Any]) {

//        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
//            // We got an image.
//            inline(image: image, forMediaWithInfo: info)
//        } else {
//            // We got something from picker that is not an image. Probalby video/movie.
//            attachVideo(forMediaWithInfo: info)
//        }
//
//        dismiss(animated: true, completion: nil)
//        guard
//            let lastFirstResponder = tableView.cellForRow(at: currentCellIndexPath) as? MessageBodyCell
//            else {
//                Log.shared.errorAndCrash(component: #function, errorString: "Problem!")
//                return
//        }
//        lastFirstResponder.makeBecomeFirstResponder(inTableView: tableView)
    }
}


// MARK: - UINavigationControllerDelegate

extension MediaAttachmentPickerProvider: UINavigationControllerDelegate {
//    // Forward all methods to navigationDelegate//IOS-1369: YAGNI?
}



