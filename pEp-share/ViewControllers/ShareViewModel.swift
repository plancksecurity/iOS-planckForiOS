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
import pEpIOSToolboxForExtensions

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

    /// No account has yet been set up, sharing is impossible.
    func noAccount()

    /// User has tapped "Send", nothing to do now except wait for success or error.
    /// In response, prevent further UI actions (like tapping "Send" directly again), maybe display some animation.
    func messageIsBeingSent()

    /// This type of attachment is not (yet) supported
    func attachmentTypeNotSupported()
}

class ShareViewModel {
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
                    loadFile(dispatchGroup: dispatchGroup,
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
                    loadFileFromData(dispatchGroup: dispatchGroup,
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

        let initData = ComposeViewModel.InitData(prefilledFrom: defaultAccount.user,
                                                 bodyHtml: NSAttributedString(attributedString: bodyHtml),
                                                 inlinedAttachments: inlinedAttachments,
                                                 nonInlinedAttachments: nonInlinedAttachments)
        return initData
    }

    private func getPlainText(dispatchGroup: DispatchGroup,
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

    private func getUrl(dispatchGroup: DispatchGroup,
                        sharedData: SharedData,
                        extensionItem: NSExtensionItem,
                        attributedTitle: NSAttributedString?,
                        itemProvider: NSItemProvider) {
        let completionHandler: ((NSSecureCoding?, Error?) -> Void) = { item, error in
            if let theUrl = item as? URL {
                sharedData.add(itemProvider: itemProvider,
                               dataWithType: .url(attributedTitle, theUrl))
            } else if let error = error {
                Log.shared.log(error: error)
            } else {
                Log.shared.logError(message: "Error without error. Could not read a URL from NSSecureCoding.")
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
                              completionHandler: { item, error in
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
        itemProvider.loadItem(forTypeIdentifier: kUTTypeFileURL as String,
                              options: nil,
                              completionHandler: { [weak self] item, error in
                                if let fileUrl = item as? URL {
                                    guard let me = self else {
                                        // assume ok, user moved on
                                        dispatchGroup.leave()
                                        return
                                    }

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
                                                                               filename,  mimeType,
                                                                               data))
                                        } catch {
                                            Log.shared.log(error: error)
                                        }
                                        dispatchGroup.leave()
                                    }
                                } else if let error = error {
                                    Log.shared.log(error: error)
                                } else {
                                    // no data loading was triggered, since we have no url
                                    dispatchGroup.leave()
                                }
                              })
    }

    private func loadFileFromData(dispatchGroup: DispatchGroup,
                                  sharedData: SharedData,
                                  extensionItem: NSExtensionItem,
                                  attributedTitle: NSAttributedString?,
                                  itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: kUTTypeContent as String,
                              options: nil,
                              completionHandler: { [weak self] item, error in
                                if let data = item as? Data {
                                    guard let me = self else {
                                        // assume ok, user moved on
                                        dispatchGroup.leave()
                                        return
                                    }

                                    dispatchGroup.leave()
                                } else if let error = error {
                                    Log.shared.log(error: error)
                                } else {
                                    // no data loading was triggered, since we have no url
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
