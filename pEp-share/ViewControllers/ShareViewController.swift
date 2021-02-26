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

// MARK: - Private (WIP)

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
            guard let inputItem = anyItem as? NSExtensionItem else {
                continue
            }
            guard let attachments = inputItem.attachments else {
                continue
            }
            for attachment in attachments {
                if let attributedTitle = inputItem.attributedTitle {
                    print("*** attachment title \(attributedTitle)")
                }
                if attachment.hasItemConformingToTypeIdentifier(ShareViewController.utiPlainText) {
                    dispatchGroup.enter()
                    loadPlainText(dispatchGroup: dispatchGroup, item: attachment)
                } else if attachment.hasItemConformingToTypeIdentifier(ShareViewController.utiImage) {
                    loadImage(dispatchGroup: dispatchGroup, item: attachment)
                } else if attachment.hasItemConformingToTypeIdentifier(ShareViewController.utiUrl) {
                    loadFile(item: attachment)
                }
            }
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let me = self else {
                // user canceled early
                return
            }
            dispatchGroup.wait()
            me.presentComposeVC()
        }
    }

    private func loadPlainText(dispatchGroup: DispatchGroup, item: NSItemProvider) {
        item.loadItem(forTypeIdentifier: "public.plain-text", options: nil, completionHandler: { [weak self] item, error in
            if let text = item as? String {
                // TODO: Store the result
                dispatchGroup.leave()
            }
        })
    }

    private func loadImage(dispatchGroup: DispatchGroup, item: NSItemProvider) {
        item.loadItem(forTypeIdentifier: "public.jpeg", options: nil, completionHandler: { [weak self] item, error in

            guard let me = self else {
                // assuming the extension can be canceled by the user
                return
            }

            if let imgUrl = item as? URL,
               let imgData = try? Data(contentsOf: imgUrl),
               let img = UIImage(data: imgData) {
                // TODO: Store the result
            }
            dispatchGroup.leave()
        })
    }

    private func loadFile(item: NSItemProvider) {
        // TODO: - not yet implemented
        Log.shared.debug("DEV: load PDF element is not yet implemented!")
    }
}
