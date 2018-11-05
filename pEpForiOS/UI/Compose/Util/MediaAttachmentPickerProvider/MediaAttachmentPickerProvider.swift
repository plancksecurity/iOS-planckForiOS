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
    }

    private func setup() {
        imagePicker.delegate = self
        if let mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) {
            imagePicker.mediaTypes = mediaTypes
        }
    }
}

// MARK: - UIImagePickerControllerDelegate

extension MediaAttachmentPickerProvider: UIImagePickerControllerDelegate {

    public func imagePickerController( _ picker: UIImagePickerController,
                                       didFinishPickingMediaWithInfo info: [String: Any]) {
        viewModel?.handleDidFinishPickingMedia(info: info)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        viewModel?.handleDidCancel()
    }
}

// MARK: - UINavigationControllerDelegate

extension MediaAttachmentPickerProvider: UINavigationControllerDelegate {
    // We need to conform to this to be able to set ourself as UIImagePickerController.delegate.
    // So far there is nothing to handle though.
}
