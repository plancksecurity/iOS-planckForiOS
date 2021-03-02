//
//  ShareViewModel.swift
//  pEp-share
//
//  Created by Dirk Zimmermann on 01.03.21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

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
                if itemProvider.hasItemConformingToTypeIdentifier(ShareViewModel.utiPlainText) {
                    dispatchGroup.enter()
                    loadPlainText(dispatchGroup: dispatchGroup,
                                  sharedData: sharedData,
                                  extensionItem: extensionItem,
                                  attributedTitle: attributedTitle,
                                  itemProvider: itemProvider)
                } else if itemProvider.hasItemConformingToTypeIdentifier(ShareViewModel.utiImage) {
                    dispatchGroup.enter()
                    loadImage(dispatchGroup: dispatchGroup,
                              sharedData: sharedData,
                              extensionItem: extensionItem,
                              attributedTitle: attributedTitle,
                              itemProvider: itemProvider)
                } else if itemProvider.hasItemConformingToTypeIdentifier(ShareViewModel.utiUrl) {
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
}

extension ShareViewModel {
    private static let utiPlainText = "public.plain-text"
    private static let utiImage = "public.image"
    private static let utiUrl = "public.file-url"

    private func loadPlainText(dispatchGroup: DispatchGroup,
                               sharedData: SharedData,
                               extensionItem: NSExtensionItem,
                               attributedTitle: NSAttributedString?,
                               itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: ShareViewModel.utiPlainText,
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
        itemProvider.loadItem(forTypeIdentifier: ShareViewModel.utiImage,
                              options: nil,
                              completionHandler: { item, error in
                                if let imgUrl = item as? URL,
                                   let imgData = try? Data(contentsOf: imgUrl),
                                   let img = UIImage(data: imgData) {
                                    sharedData.add(itemProvider: itemProvider,
                                                   dataWithType: .image(attributedTitle, img))
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
