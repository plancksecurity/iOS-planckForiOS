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
                if let attributedTitle = extensionItem.attributedTitle {
                    print("*** attachment title \(attributedTitle)")
                }
                foundItemProviders.append(itemProvider)
                if itemProvider.hasItemConformingToTypeIdentifier(ShareViewModel.utiPlainText) {
                    dispatchGroup.enter()
                    loadPlainText(dispatchGroup: dispatchGroup,
                                  sharedData: sharedData,
                                  extensionItem: extensionItem,
                                  itemProvider: itemProvider)
                } else if itemProvider.hasItemConformingToTypeIdentifier(ShareViewModel.utiImage) {
                    dispatchGroup.enter()
                    loadImage(dispatchGroup: dispatchGroup,
                              sharedData: sharedData,
                              extensionItem: extensionItem,
                              itemProvider: itemProvider)
                } else if itemProvider.hasItemConformingToTypeIdentifier(ShareViewModel.utiUrl) {
                    loadFile(dispatchGroup: dispatchGroup,
                             sharedData: sharedData,
                             extensionItem: extensionItem,
                             itemProvider: itemProvider)
                }
            }
        }

        // the action to execute when all shared data has been loaded
        let finishWorkItem = DispatchWorkItem(qos: .userInitiated, flags: []) { [weak self] in
            guard let me = self else {
                // user canceled early
                return
            }

            for itemProvider in foundItemProviders {
                
            }
            // TODO: Inform the VC
            //me.presentComposeVC()
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
                               itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: ShareViewModel.utiPlainText,
                              options: nil,
                              completionHandler: { item, error in
                                if let text = item as? String {
                                    sharedData.add(extensionItem: extensionItem,
                                                   dataWithType: .plainText(text))
                                } else if let error = error {
                                    Log.shared.log(error: error)
                                }
                                dispatchGroup.leave()
                              })
    }

    private func loadImage(dispatchGroup: DispatchGroup,
                           sharedData: SharedData,
                           extensionItem: NSExtensionItem,
                           itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: ShareViewModel.utiImage,
                              options: nil,
                              completionHandler: { item, error in
                                if let imgUrl = item as? URL,
                                   let imgData = try? Data(contentsOf: imgUrl),
                                   let img = UIImage(data: imgData) {
                                    sharedData.add(extensionItem: extensionItem,
                                                   dataWithType: .image(img))
                                } else if let error = error {
                                    Log.shared.log(error: error)
                                }
                                dispatchGroup.leave()
                              })
    }

    private func loadFile(dispatchGroup: DispatchGroup,
                          sharedData: SharedData,
                          extensionItem: NSExtensionItem,
                          itemProvider: NSItemProvider) {
        // TODO: - not yet implemented
        Log.shared.debug("DEV: load PDF element is not yet implemented!")
    }
}
