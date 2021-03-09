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
    /// All documents to be shared have been downloaded
    /// (asynchronously), ready to show the compose view
    /// with the given model.
    func startComposeView(composeViewModel: ComposeViewModel)

    /// User wanted to send, but there were problems creating the
    /// outgoing message
    func outgoingMessageCouldNotBeSaved()

    /// The user canceled before sending
    func canceledByUser()

    /// If called with a nil `Error`, the message was succesfully sent,
    /// if not, `error` will contain the error.
    func messageSent(error: Error?)
}

class ShareViewModel {
    public weak var shareViewModelDelegate: ShareViewModelDelegate?

    public init(encryptAndSendSharing: EncryptAndSendSharingProtocol? = nil) {
        self.enrcyptAndSendSharing = encryptAndSendSharing ?? EncryptAndSendSharing()
    }

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
                    getPlainText(dispatchGroup: dispatchGroup,
                                 sharedData: sharedData,
                                 extensionItem: extensionItem,
                                 attributedTitle: attributedTitle,
                                 itemProvider: itemProvider)
                } else if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                    getUrl(dispatchGroup: dispatchGroup,
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

            let composeVM = me.composeViewModel(sharedTypes: sharedData.allSharedTypes())
            me.shareViewModelDelegate?.startComposeView(composeViewModel: composeVM)
        }

        // let the dispatch group call us when all is done
        dispatchGroup.notify(queue: DispatchQueue.main, work: finishWorkItem)
    }

    /// Creates a `ComposeViewModel.InitData` from shared data, suitable for creating a compose view model.
    public func composeInitData(sharedTypes: [SharedType]) -> ComposeViewModel.InitData {
        let bodyHtml = NSMutableAttributedString(string: "")

        var inlinedAttachments = [Attachment]()

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

                let imageWidth: CGFloat = 200.0 // arbitrary, but should fit all devices

                let session = Session()
                session.performAndWait() {
                    let attachment = Attachment(data: imageData,
                                                mimeType: mimeType,
                                                image: image,
                                                contentDisposition: .inline,
                                                session: session)
                    inlinedAttachments.append(attachment)
                    bodyHtml.append(attachment.inlinedText(scaleToImageWidth: imageWidth,
                                                           attachmentWidth: imageWidth))
                }

            default: // TODO: Implement all cases
                break
            }
        }

        guard let defaultAccount = Account.defaultAccount() else {
            // TODO: Indicate the error to the user (UI)
            Log.shared.errorAndCrash(message: "Sharing extension needs an account to send from")
            return ComposeViewModel.InitData()
        }

        let initData = ComposeViewModel.InitData(prefilledFrom: defaultAccount.user,
                                                 subject: NSLocalizedString("Shared Files",
                                                                            comment: "Standard subject for sharing files"),
                                                 bodyHtml: NSAttributedString(attributedString: bodyHtml),
                                                 inlinedAttachments: inlinedAttachments,
                                                 nonInlinedAttachments: [])
        return initData
    }

    /// Creates a compose VM from the given shared data.
    public func composeViewModel(sharedTypes: [SharedType]) -> ComposeViewModel {
        let initData = composeInitData(sharedTypes: sharedTypes)
        let composeVMState = ComposeViewModel.ComposeViewModelState(initData: initData, delegate: nil)
        let composeViewModel = ComposeViewModel(state: composeVMState,
                                                offerToSaveDraftOnCancel: false)
        composeViewModel.composeViewModelEndActionDelegate = self
        return composeViewModel
    }

    // MARK - Private

    private let encryptAndSendSharing: EncryptAndSendSharingProtocol
}

extension ShareViewModel {
    private func getPlainText(dispatchGroup: DispatchGroup,
                              sharedData: SharedData,
                              extensionItem: NSExtensionItem,
                              attributedTitle: NSAttributedString?,
                              itemProvider: NSItemProvider) {
        // TODO: Do we really have to "load" a simple text? Test.
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

    private func getUrl(dispatchGroup: DispatchGroup,
                        sharedData: SharedData,
                        extensionItem: NSExtensionItem,
                        attributedTitle: NSAttributedString?,
                        itemProvider: NSItemProvider) {
        // TODO: Does this really "load" the URL as String? Test.
        itemProvider.loadItem(forTypeIdentifier: kUTTypePlainText as String,
                              options: nil,
                              completionHandler: { item, error in
                                if let text = item as? String,
                                   let url = URL(string: text) {
                                    sharedData.add(itemProvider: itemProvider,
                                                   dataWithType: .url(attributedTitle, url))
                                } else if let error = error {
                                    Log.shared.log(error: error)
                                } else {
                                    Log.shared.logError(message: "Error without error. Maybe the url was malformed.")
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

extension ShareViewModel: ComposeViewModelFinalActionDelegate {
    func userWantsToSend(message: Message) {
        // TODO
    }

    func couldNotCreateOutgoingMessage() {
        shareViewModelDelegate?.outgoingMessageCouldNotBeSaved()
    }

    func canceled() {
        shareViewModelDelegate?.canceledByUser()
    }
}
