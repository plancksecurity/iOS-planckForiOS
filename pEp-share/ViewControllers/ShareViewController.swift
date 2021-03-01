//
//  ShareViewController.swift
//  pEp-share
//
//  Created by Adam Kowalski on 14/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

import PEPIOSToolboxForAppExtensions

final class ShareViewController: UIViewController {
    var composeViewController: ComposeViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupComposeVC()
        checkInputItems()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ComposeViewController {
        }
    }

    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}

// MARK: - Private Extension

extension ShareViewController {
    private static let utiPlainText = "public.plain-text"
    private static let utiImage = "public.image"
    private static let utiUrl = "public.file-url"

    private func setupComposeVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let composeVC = storyboard.instantiateViewController(withIdentifier: ComposeViewController.storyboardId) as? ComposeViewController else {
            Log.shared.errorAndCrash("Cannot instantiate ComposeViewController")
            return
        }
        composeViewController = composeVC
    }

    private func presentComposeVC() {
        guard let composeVC = composeViewController else {
            Log.shared.errorAndCrash("Have not instantiated yet a ComposeViewController")
            return
        }
        present(composeVC, animated: true, completion: nil)
    }

    private func checkInputItems() {
        guard let context = extensionContext else {
            Log.shared.errorAndCrash(message: "Lost extension context!")
            return
        }

        let dispatchGroup = DispatchGroup()

        for anyItem in context.inputItems {
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
                if itemProvider.hasItemConformingToTypeIdentifier(ShareViewController.utiPlainText) {
                    dispatchGroup.enter()
                    loadPlainText(dispatchGroup: dispatchGroup, itemProvider: itemProvider)
                } else if itemProvider.hasItemConformingToTypeIdentifier(ShareViewController.utiImage) {
                    dispatchGroup.enter()
                    loadImage(dispatchGroup: dispatchGroup, itemProvider: itemProvider)
                } else if itemProvider.hasItemConformingToTypeIdentifier(ShareViewController.utiUrl) {
                    loadFile(itemProvider: itemProvider)
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
                me.presentComposeVC()
            }
        }
    }

    private func loadPlainText(dispatchGroup: DispatchGroup, itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: ShareViewController.utiPlainText,
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

    private func loadImage(dispatchGroup: DispatchGroup, itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: ShareViewController.utiImage,
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

    private func loadFile(itemProvider: NSItemProvider) {
        // TODO: - not yet implemented
        Log.shared.debug("DEV: load PDF element is not yet implemented!")
    }
}
