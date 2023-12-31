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
import PlanckToolboxForExtensions

protocol ShareViewModelDelegate: AnyObject {
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

    /// No account has yet been set up, sharing is impossible.
    func noAccount()

    /// User has tapped "Send", nothing to do now except wait for success or error.
    /// In response, prevent further UI actions (like tapping "Send" directly again), maybe display some animation.
    func messageIsBeingSent()

    /// This type of attachment is not (yet) supported
    func attachmentTypeNotSupported()

    /// An error ocurred when trying to fetch the attachment, or during processing (i.e., there were problems
    /// with the data).
    func attachmentCouldNotBeLoaded(error: Error?)

    /// The combined size of the attachments exceed a certain limit that would likely
    /// lead to memory related crashes, due the 120 MB heap restriction for extensions.
    /// Inform the user and cancel the extension.
    func attachmentLimitExceeded()
}

class ShareViewModel {
    /// Maximum allowed size of all attachments, in MB
    public static let maximumAttachmentSize = 7

    public weak var shareViewModelDelegate: ShareViewModelDelegate?

    public init(encryptAndSendSharing: EncryptAndSendSharingProtocol? = nil) {
        self.encryptAndSendSharing = encryptAndSendSharing ?? EncryptAndSendSharing()
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

                if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                    foundItemProviders.append(itemProvider)
                    dispatchGroup.enter()
                    loadImage(dispatchGroup: dispatchGroup,
                              sharedData: sharedData,
                              extensionItem: extensionItem,
                              attributedTitle: attributedTitle,
                              itemProvider: itemProvider)
                } else if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeFileURL as String) {
                    foundItemProviders.append(itemProvider)
                    dispatchGroup.enter()
                    loadFile(utiString: kUTTypeFileURL as String,
                             dispatchGroup: dispatchGroup,
                             sharedData: sharedData,
                             extensionItem: extensionItem,
                             attributedTitle: attributedTitle,
                             itemProvider: itemProvider)
                } else if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                    foundItemProviders.append(itemProvider)
                    dispatchGroup.enter()
                    getUrl(dispatchGroup: dispatchGroup,
                           sharedData: sharedData,
                           extensionItem: extensionItem,
                           attributedTitle: attributedTitle,
                           itemProvider: itemProvider)
                } else if itemProvider.hasItemConformingToTypeIdentifier(kUTTypePlainText as String) {
                    foundItemProviders.append(itemProvider)
                    dispatchGroup.enter()
                    getPlainText(dispatchGroup: dispatchGroup,
                                 sharedData: sharedData,
                                 extensionItem: extensionItem,
                                 attributedTitle: attributedTitle,
                                 itemProvider: itemProvider)
                } else if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeContent as String) {
                    foundItemProviders.append(itemProvider)
                    dispatchGroup.enter()
                    loadFile(utiString: kUTTypeContent as String,
                             dispatchGroup: dispatchGroup,
                             sharedData: sharedData,
                             extensionItem: extensionItem,
                             attributedTitle: attributedTitle,
                             itemProvider: itemProvider)
                } else {
                    shareViewModelDelegate?.attachmentTypeNotSupported()
                }
            }
        }

        // the action to execute when all shared data has been loaded
        let finishWorkItem = DispatchWorkItem(qos: .userInitiated, flags: []) { [weak self] in
            guard let me = self else {
                // assume user somehow canceled early
                return
            }

            do {
                let composeVM = try me.composeViewModel(sharedTypes: sharedData.allSharedTypes())
                me.shareViewModelDelegate?.startComposeView(composeViewModel: composeVM)
            } catch MessageCreationError.noAccount {
                me.shareViewModelDelegate?.noAccount()
            } catch MessageCreationError.attachmentLimitExceeded {
                me.shareViewModelDelegate?.attachmentLimitExceeded()
            } catch {
                Log.shared.errorAndCrash(error: error)
                me.shareViewModelDelegate?.canceledByUser()
            }
        }

        // let the dispatch group call us when all is done
        dispatchGroup.notify(queue: DispatchQueue.main, work: finishWorkItem)
    }

    // MARK: - Private

    private let encryptAndSendSharing: EncryptAndSendSharingProtocol

    private let internalQueue = DispatchQueue(label: "ShareViewModelInternalQueue")
}

extension ShareViewModel {
    /// Errors that can occurr during message/model creations
    private enum MessageCreationError: Error {
        /// There is no account that can be used.
        case noAccount

        /// The combined size of the attachments exceed a certain limit that would likely
        /// lead to memory related crashes, due the 120 MB heap restriction for extensions
        case attachmentLimitExceeded
    }

    /// Creates a compose VM from the given shared data.
    private func composeViewModel(sharedTypes: [SharedType]) throws -> ComposeViewModel {
        let initData = try composeInitData(sharedTypes: sharedTypes)
        let composeVMState = ComposeViewModel.ComposeViewModelState(initData: initData, delegate: nil)
        let composeViewModel = ComposeViewModel(state: composeVMState,
                                                offerToSaveDraftOnCancel: false)
        composeViewModel.composeViewModelEndActionDelegate = self
        return composeViewModel
    }

    /// Creates a `ComposeViewModel.InitData` from shared data, suitable for creating a compose view model.
    private func composeInitData(sharedTypes: [SharedType]) throws -> ComposeViewModel.InitData {
        func addNewTitleToTheBody(bodyHtml: NSMutableAttributedString, title: NSAttributedString?) {
            if bodyHtml.length > 0 {
                bodyHtml.append(NSAttributedString(string: "\n\n"))
            }
            if let theTitle = title {
                bodyHtml.append(theTitle)
                bodyHtml.append(NSAttributedString(string: "\n"))
            }
        }

        let bodyHtml = NSMutableAttributedString(string: "")

        var inlinedAttachments = [Attachment]()
        var nonInlinedAttachments = [Attachment]()

        for sharedType in sharedTypes {
            switch sharedType {
            case .image(let title, let filename, let image, let imageData, let mimeType):
                addNewTitleToTheBody(bodyHtml: bodyHtml, title: title)

                let imageWidth: CGFloat = 200.0 // arbitrary, but should fit all devices

                let session = Session()
                session.performAndWait() {
                    let attachment = Attachment(data: imageData,
                                                mimeType: mimeType,
                                                fileName: filename,
                                                image: image,
                                                contentDisposition: .inline,
                                                session: session)
                    inlinedAttachments.append(attachment)
                    bodyHtml.append(attachment.inlinedText(scaleToImageWidth: imageWidth,
                                                           attachmentWidth: imageWidth))
                }

            case .url(let title, let url):
                addNewTitleToTheBody(bodyHtml: bodyHtml, title: title)
                bodyHtml.append(NSAttributedString(string: "\(url)"))

            case .plainText(let title, let text):
                addNewTitleToTheBody(bodyHtml: bodyHtml, title: title)
                bodyHtml.append(NSAttributedString(string: text))
                break

            case .file(let title, let filename, let mimeType, let fileData):
                addNewTitleToTheBody(bodyHtml: bodyHtml, title: title)
                let session = Session()
                session.performAndWait() {
                    let attachment = Attachment(data: fileData,
                                                mimeType: mimeType,
                                                fileName: filename,
                                                contentDisposition: .attachment,
                                                session: session)
                    nonInlinedAttachments.append(attachment)
                }
                break
            }
        }

        guard let defaultAccount = Account.defaultAccount() else {
            throw MessageCreationError.noAccount
        }

        var allAttachments = inlinedAttachments
        allAttachments.append(contentsOf: nonInlinedAttachments)
        // will throw and pass to upper layers if maximum attachment size exceeded
        try checkAttachmentSize(attachments: allAttachments)

        let initData = ComposeViewModel.InitData(prefilledFrom: defaultAccount.user,
                                                 bodyHtml: NSAttributedString(attributedString: bodyHtml),
                                                 inlinedAttachments: inlinedAttachments,
                                                 nonInlinedAttachments: nonInlinedAttachments)
        return initData
    }

    private func checkAttachmentSize(attachments: [Attachment]) throws {
        var totalAttachmentSize = 0
        for attach in attachments {
            totalAttachmentSize += attach.size ?? 0
        }
        if totalAttachmentSize > ShareViewModel.maximumAttachmentSize * 1024 * 1024 {
            throw MessageCreationError.attachmentLimitExceeded
        }
    }

    private func getPlainText(dispatchGroup: DispatchGroup,
                              sharedData: SharedData,
                              extensionItem: NSExtensionItem,
                              attributedTitle: NSAttributedString?,
                              itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: kUTTypePlainText as String,
                              options: nil,
                              completionHandler: { [weak self] item, error in
                                guard let me = self else {
                                    // assume user somehow canceled early
                                    dispatchGroup.leave()
                                    return
                                }

                                if let text = item as? String {
                                    sharedData.add(itemProvider: itemProvider,
                                                   dataWithType: .plainText(attributedTitle, text))
                                } else {
                                    me.shareViewModelDelegate?.attachmentCouldNotBeLoaded(error: error)
                                }
                                dispatchGroup.leave()
                              })
    }

    private func getUrl(dispatchGroup: DispatchGroup,
                        sharedData: SharedData,
                        extensionItem: NSExtensionItem,
                        attributedTitle: NSAttributedString?,
                        itemProvider: NSItemProvider) {
        let completionHandler: ((NSSecureCoding?, Error?) -> Void) = { [weak self] item, error in
            guard let me = self else {
                // assume user somehow canceled early
                dispatchGroup.leave()
                return
            }

            if let theUrl = item as? URL {
                sharedData.add(itemProvider: itemProvider,
                               dataWithType: .url(attributedTitle, theUrl))
            } else {
                me.shareViewModelDelegate?.attachmentCouldNotBeLoaded(error: error)
            }
            dispatchGroup.leave()
        }
        itemProvider.loadItem(forTypeIdentifier: kUTTypeURL as String,
                              options: nil,
                              completionHandler: completionHandler)
    }

    private func loadImage(dispatchGroup: DispatchGroup,
                           sharedData: SharedData,
                           extensionItem: NSExtensionItem,
                           attributedTitle: NSAttributedString?,
                           itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: kUTTypeImage as String,
                              options: nil,
                              completionHandler: { [weak self] item, error in
            guard let me = self else {
                // assume user somehow canceled early
                dispatchGroup.leave()
                return
            }
            if let imgUrl = item as? URL,
               let imgData = try? Data(contentsOf: imgUrl),
               let img = UIImage(data: imgData) {
                let mimeType = itemProvider.supportedMimeTypeForInlineAttachment() ?? MimeTypeUtils.mimeType(fromURL: imgUrl)
                let filename = imgUrl.fileName(includingExtension: true)
                sharedData.add(itemProvider: itemProvider,
                               dataWithType: .image(attributedTitle,
                                                    filename,
                                                    img,
                                                    imgData,
                                                    mimeType))
            } else if let img = item as? UIImage,
                      let data = img.jpeg(.low) {
                let defaultImageName = "image"
                let mimeType = itemProvider.supportedMimeTypeForInlineAttachment() ?? MimeTypeUtils.mimeType(fromFileExtension: "jpg")
                sharedData.add(itemProvider: itemProvider,
                               dataWithType: .image(attributedTitle,
                                                    defaultImageName,
                                                    img,
                                                    data,
                                                    mimeType))
            } else {
                me.shareViewModelDelegate?.attachmentCouldNotBeLoaded(error: error)
            }
            dispatchGroup.leave()
        })
         
    }

    private func loadFile(utiString: String,
                          dispatchGroup: DispatchGroup,
                          sharedData: SharedData,
                          extensionItem: NSExtensionItem,
                          attributedTitle: NSAttributedString?,
                          itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: utiString,
                              options: nil,
                              completionHandler: { [weak self] item, error in
                                guard let me = self else {
                                    // assume ok, user moved on
                                    dispatchGroup.leave()
                                    return
                                }

                                if let fileUrl = item as? URL {
                                    var filename = fileUrl.fileName()
                                    let fileExt = fileUrl.pathExtension
                                    if !fileExt.isEmpty {
                                        filename = "\(filename).\(fileExt)"
                                    }

                                    let mimeType = MimeTypeUtils.mimeType(fromURL: fileUrl)

                                    // It's not clear whether we are _guaranteed_ to land
                                    // in a background thread with completion, so use our own
                                    me.internalQueue.async {
                                        do {
                                            let data = try Data(contentsOf: fileUrl)
                                            sharedData.add(itemProvider: itemProvider,
                                                           dataWithType: .file(attributedTitle,
                                                                               filename,
                                                                               mimeType,
                                                                               data))
                                        } catch {
                                            Log.shared.log(error: error)
                                            me.shareViewModelDelegate?.attachmentCouldNotBeLoaded(error: error)
                                        }
                                        dispatchGroup.leave()
                                    }
                                } else {
                                    me.shareViewModelDelegate?.attachmentCouldNotBeLoaded(error: error)
                                    dispatchGroup.leave()
                                }
                              })
    }
}

extension ShareViewModel: ComposeViewModelFinalActionDelegate {
    func userWantsToSend(message: Message) {
        shareViewModelDelegate?.messageIsBeingSent()
        encryptAndSendSharing.send(message: message) { [weak self] error in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.shareViewModelDelegate?.messageSent(error: error)
        }
    }

    func couldNotCreateOutgoingMessage() {
        shareViewModelDelegate?.outgoingMessageCouldNotBeSaved()
    }

    func canceled() {
        shareViewModelDelegate?.canceledByUser()
    }
}
