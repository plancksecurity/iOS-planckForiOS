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
                                       didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

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

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}
