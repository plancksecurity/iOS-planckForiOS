//
//  MediaAttachmentPickerProvider.swift
//  pEp
//
//  Created by Andreas Buff on 19.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers
import PhotosUI
#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

class MediaAttachmentPickerProvider: NSObject {
    public private(set) var imagePicker = UIImagePickerController()

    public var viewModel: MediaAttachmentPickerProviderViewModel?

    // MARK: - Setup

    init(with viewModel: MediaAttachmentPickerProviderViewModel) {
        self.viewModel = viewModel
        super.init()
        setup()
    }

    /// Retrieve the picker if possible, otherwise nil.
    /// It could be nil due lack of permissions.
    /// - Parameters:
    ///   - requesterViewController: The VC that request the picker will be used to show alert to inform the user in case no permission is granted for iOS versions less than 14. 
    ///   - callback: The callback with the picker.
    public func getPicker(from requesterViewController: UIViewController, _ callback: @escaping (UIViewController?) -> ()?) {
        if #available(iOS 14.0, *) {
            var configuration = PHPickerConfiguration()
            configuration.filter = .any(of: [.livePhotos, .images, .videos])
            configuration.preferredAssetRepresentationMode = .current
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            callback(picker)
        } else {
            let media = Capability.media
            media.requestAndInformUserInErrorCase(viewController: requesterViewController)
            { [weak self] (permissionsGranted: Bool, error: Capability.AccessError?) in
                guard permissionsGranted else {
                    callback(nil)
                    return
                }
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }
                callback(me.imagePicker)
            }
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
        processResults(results: results)
    }
}

// MARK: - Private

extension MediaAttachmentPickerProvider {

    private func setup() {
        imagePicker.delegate = self
        if let mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) {
            imagePicker.mediaTypes = mediaTypes
        }
    }

    @available(iOS 14, *)
    private func processResults(results: [PHPickerResult]) {
        results.forEach { result in
            let provider = result.itemProvider
            [UTType.image.identifier, UTType.movie.identifier].forEach { identifier in
                if provider.hasItemConformingToTypeIdentifier(identifier) {
                    provider.loadFileRepresentation(forTypeIdentifier: identifier) { [weak self] (url, error) in
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
                        switch identifier {
                        case UTType.image.identifier:
                            do {
                                let data = try Data(contentsOf: url)
                                guard let image = UIImage(data: data) else {
                                    Log.shared.logError(message: "Image not found")
                                    return
                                }
                                me.viewModel?.handleDidFinishPickingImage(url: url, image: image)
                            } catch let err {
                                Log.shared.error("%@", "\(err)")
                            }
                        case UTType.movie.identifier:
                            me.viewModel?.handleDidFinishPickingVideoAt(url: url)
                        default:
                            Log.shared.errorAndCrash("Unhandled UTType")
                        }
                    }
                }
            }
        }
    }
}

