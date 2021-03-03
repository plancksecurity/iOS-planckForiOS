//
//  ShareViewModel.swift
//  pEp-share
//
//  Created by Dirk Zimmermann on 01.03.21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices

import MessageModelForAppExtensions
import PEPIOSToolboxForAppExtensions

protocol ShareViewModelDelegate: class {
    /// All documents to be shared have been downloaded, ready to show the compose view.
    func startComposeView(sharedTypes: [SharedType])
}

class ShareViewModel {
    public weak var shareViewModelDelegate: ShareViewModelDelegate?

    /// Load all eligible files from the extension context and inform the delegate when done.
    public func loadInputItems(extensionContext: NSExtensionContext) {
        let sharedData = SharedData()
        let dispatchGroup = DispatchGroup()
        var foundItemProviders = [NSItemProvider]()

        for anyItem in extensionContext.inputItems {
            guard let extensionItem = anyItem as? NSExtensionItem else {
                continue
            }
            guard let itemProviders = extensionItem.attachments else {
                continue
            }
            for itemProvider in itemProviders {
                let attributedTitle = extensionItem.attributedTitle
                foundItemProviders.append(itemProvider)
                if itemProvider.hasItemConformingToTypeIdentifier(kUTTypePlainText as String) {
                    dispatchGroup.enter()
                    loadPlainText(dispatchGroup: dispatchGroup,
                                  sharedData: sharedData,
                                  extensionItem: extensionItem,
                                  attributedTitle: attributedTitle,
                                  itemProvider: itemProvider)
                } else if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                    dispatchGroup.enter()
                    loadImage(dispatchGroup: dispatchGroup,
                              sharedData: sharedData,
                              extensionItem: extensionItem,
                              attributedTitle: attributedTitle,
                              itemProvider: itemProvider)
                } else if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeFileURL as String) {
                    loadFile(dispatchGroup: dispatchGroup,
                             sharedData: sharedData,
                             extensionItem: extensionItem,
                             attributedTitle: attributedTitle,
                             itemProvider: itemProvider)
                }
            }
        }

        // the action to execute when all shared data has been loaded
        let finishWorkItem = DispatchWorkItem(qos: .userInitiated, flags: []) { [weak self] in
            guard let me = self else {
                // assume user canceled early
                return
            }

            me.shareViewModelDelegate?.startComposeView(sharedTypes: sharedData.allSharedTypes())
        }

        // let the dispatch group call us when all is done
        dispatchGroup.notify(queue: DispatchQueue.main, work: finishWorkItem)
    }

    /// Shadows `SharedType` but without any associated types,
    /// used for tracking the types shared in one step.
    private enum MediaType {
        case image
        case url
        case file
    }

    /// Creates a `ComposeViewModel.InitData` from shared data, suitable for creating a compose view model.
    static public func composeInitData(sharedTypes: [SharedType]) -> ComposeViewModel.InitData {
        let bodyHtml = NSMutableAttributedString(string: "")

        var inlinedAttachments = [Attachment]()
        var alreadySharedMediaTypes = [MediaType:Bool]()

        for sharedType in sharedTypes {
            switch sharedType {
            case .image(let title, let image, let imageData, let mimeType):
                if bodyHtml.length > 0 {
                    bodyHtml.append(NSAttributedString(string: "\n\n"))
                }
                if let theTitle = title {
                    bodyHtml.append(theTitle)
                    bodyHtml.append(NSAttributedString(string: "\n"))
                }

                let attachment = Attachment(data: imageData,
                                            mimeType: mimeType,
                                            image: image,
                                            contentDisposition: .inline)
                inlinedAttachments.append(attachment)

                let imageWidth: CGFloat = 200.0 // arbitrary, but should fit all devices
                bodyHtml.append(attachment.inlinedText(scaleToImageWidth: imageWidth,
                                                       attachmentWidth: imageWidth))

            default: // TODO: Remove default and explicitly handle all cases
                break
            }
        }

        let initData = ComposeViewModel.InitData(subject: "Shared",
                                                 bodyHtml: NSAttributedString(attributedString: bodyHtml),
                                                 inlinedAttachments: inlinedAttachments,
                                                 nonInlinedAttachments: [])
        return initData
    }

    /// Creates a compose VM from the given shared data.
    static public func composeViewModel(sharedTypes: [SharedType]) -> ComposeViewModel {
        let initData = composeInitData(sharedTypes: sharedTypes)
        let composeVMState = ComposeViewModel.ComposeViewModelState(initData: initData, delegate: nil)
        let composeViewModel = ComposeViewModel(state: composeVMState)
        return composeViewModel
    }
}

extension ShareViewModel {
    private func loadPlainText(dispatchGroup: DispatchGroup,
                               sharedData: SharedData,
                               extensionItem: NSExtensionItem,
                               attributedTitle: NSAttributedString?,
                               itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: kUTTypePlainText as String,
                              options: nil,
                              completionHandler: { item, error in
                                if let text = item as? String {
                                    sharedData.add(itemProvider: itemProvider,
                                                   dataWithType: .plainText(attributedTitle, text))
                                } else if let error = error {
                                    Log.shared.log(error: error)
                                }
                                dispatchGroup.leave()
                              })
    }

    private func loadImage(dispatchGroup: DispatchGroup,
                           sharedData: SharedData,
                           extensionItem: NSExtensionItem,
                           attributedTitle: NSAttributedString?,
                           itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: kUTTypeImage as String,
                              options: nil,
                              completionHandler: { item, error in
                                if let imgUrl = item as? URL,
                                   let imgData = try? Data(contentsOf: imgUrl),
                                   let img = UIImage(data: imgData),
                                   let mimeType = itemProvider.supportedMimeTypeForInlineAttachment() {
                                    sharedData.add(itemProvider: itemProvider,
                                                   dataWithType: .image(attributedTitle,
                                                                        img,
                                                                        imgData,
                                                                        mimeType))
                                } else if let error = error {
                                    Log.shared.log(error: error)
                                }
                                dispatchGroup.leave()
                              })
    }

    private func loadFile(dispatchGroup: DispatchGroup,
                          sharedData: SharedData,
                          extensionItem: NSExtensionItem,
                          attributedTitle: NSAttributedString?,
                          itemProvider: NSItemProvider) {
        // TODO: - not yet implemented
        Log.shared.debug("DEV: load PDF element is not yet implemented!")
    }
}
