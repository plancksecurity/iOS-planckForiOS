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

class ShareViewModel {
    public func checkInputItems(extensionContext: NSExtensionContext) {
        let dispatchGroup = DispatchGroup()

        for anyItem in extensionContext.inputItems {
            guard let extensionItem = anyItem as? NSExtensionItem else {
                continue
            }
            guard let attachments = extensionItem.attachments else {
                continue
            }
            for itemProvider in attachments {
                if let attributedTitle = extensionItem.attributedTitle {
                    print("*** attachment title \(attributedTitle)")
                }
                if itemProvider.hasItemConformingToTypeIdentifier(ShareViewModel.utiPlainText) {
                    dispatchGroup.enter()
                    loadPlainText(dispatchGroup: dispatchGroup,
                                  extensionItem: extensionItem,
                                  itemProvider: itemProvider)
                } else if itemProvider.hasItemConformingToTypeIdentifier(ShareViewModel.utiImage) {
                    dispatchGroup.enter()
                    loadImage(dispatchGroup: dispatchGroup,
                              extensionItem: extensionItem,
                              itemProvider: itemProvider)
                } else if itemProvider.hasItemConformingToTypeIdentifier(ShareViewModel.utiUrl) {
                    loadFile(dispatchGroup: dispatchGroup,
                             extensionItem: extensionItem,
                             itemProvider: itemProvider)
                }
            }
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let me = self else {
                // user canceled early
                return
            }
            dispatchGroup.wait()
            DispatchQueue.main.async {
                // TODO: Inform the VC
                //me.presentComposeVC()
            }
        }
    }
}

extension ShareViewModel {
    private static let utiPlainText = "public.plain-text"
    private static let utiImage = "public.image"
    private static let utiUrl = "public.file-url"

    private func loadPlainText(dispatchGroup: DispatchGroup,
                               extensionItem: NSExtensionItem,
                               itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: ShareViewModel.utiPlainText,
                              options: nil,
                              completionHandler: { item, error in
                                if let text = item as? String {
                                    // TODO: Store the result
                                    dispatchGroup.leave()
                                } else if let error = error {
                                    Log.shared.log(error: error)
                                }
                                dispatchGroup.leave()
                              })
    }

    private func loadImage(dispatchGroup: DispatchGroup,
                           extensionItem: NSExtensionItem,
                           itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: ShareViewModel.utiImage,
                              options: nil,
                              completionHandler: { item, error in
                                if let imgUrl = item as? URL,
                                   let imgData = try? Data(contentsOf: imgUrl),
                                   let img = UIImage(data: imgData) {
                                    // TODO: Store the result
                                } else if let error = error {
                                    Log.shared.log(error: error)
                                }
                                dispatchGroup.leave()
                              })
    }

    private func loadFile(dispatchGroup: DispatchGroup,
                          extensionItem: NSExtensionItem,
                          itemProvider: NSItemProvider) {
        // TODO: - not yet implemented
        Log.shared.debug("DEV: load PDF element is not yet implemented!")
    }
}
