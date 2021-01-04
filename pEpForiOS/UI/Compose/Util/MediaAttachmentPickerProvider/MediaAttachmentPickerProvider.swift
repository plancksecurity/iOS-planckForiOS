//
//  MediaAttachmentPickerProvider.swift
//  pEp
//
//  Created by Andreas Buff on 19.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit
import PhotosUI
import UniformTypeIdentifiers
import pEpIOSToolbox

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

// MARK: - PHPickerViewControllerDelegate
@available(iOS 14, *)
extension MediaAttachmentPickerProvider: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else {
            //There is no results to handle. Nothing to do.
            return
        }
        results.forEach { (result) in
            let provider = result.itemProvider
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { (image, error) in
                    if let error = error {
                        if UIDevice.isSimulator {
                            // Nothing to do. Simulator doesn't load images from PHPickerViewController.
                        } else {
                            Log.shared.log(error: error)
                        }
                        return
                    }
                    guard let image = image as? UIImage  else {
                        return
                    }
                    provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] (url, error) in
                        if let error = error {
                            Log.shared.log(error: error)
                            return
                        }
                        guard let me = self else {
                            Log.shared.errorAndCrash("Lost myself")
                            return
                        }
                        if let url = url {
                            me.viewModel?.handleDidFinishPickingImage(url: url, image: image)
                        }
                    }
                }
                return
            }
            if let videoIdentifier = result.videoIdentifier() {
                provider.loadFileRepresentation(forTypeIdentifier: videoIdentifier) { [weak self] (url, error) in
                    if let error = error {
                        Log.shared.log(error: error)
                        return
                    }
                    guard let me = self else {
                        Log.shared.errorAndCrash("Lost myself")
                        return
                    }
                    guard let url = url else {
                        Log.shared.errorAndCrash("No error and no url? Unexpected.")
                        return
                    }
                    me.viewModel?.handleDidFinishPickingVideoAt(url: url)
                }
            }
        }
    }
}

@available(iOS 14, *)
extension PHPickerResult {

    /// Indicates if the result is a video
    /// - Returns: If it's a video, returns the type identifier, otherwise nil
    public func videoIdentifier() -> String? {
        let identifiers = [UTType.video.identifier,
                           UTType.avi.identifier,
                           UTType.audiovisualContent.identifier,
                           UTType.mpeg2Video.identifier,
                           UTType.mpeg4Movie.identifier,
                           UTType.mpeg.identifier,
                           UTType.appleProtectedMPEG4Video.identifier,
                           UTType.quickTimeMovie.identifier]
        for identifier in identifiers {
            if itemProvider.hasItemConformingToTypeIdentifier(identifier) {
                return identifier
            }
        }
        return nil
    }
}
