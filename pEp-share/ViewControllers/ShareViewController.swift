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

        presentModalCompose()
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
    private func presentModalCompose() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let composeVC = storyboard.instantiateViewController(withIdentifier: ComposeViewController.storyboardId) as? ComposeViewController else {
            Log.shared.errorAndCrash("Cannot instantiate ComposeViewController")
            return
        }
        composeViewController = composeVC
        present(composeVC, animated: true, completion: nil)
    }

    private func checkInputItems() {
        guard let context = extensionContext else {
            Log.shared.errorAndCrash(message: "Lost extension context!")
            return
        }

        guard let item = context.inputItems.first as? NSExtensionItem,
              let attachments = item.attachments else {
            Log.shared.errorAndCrash(message: "DEV: attachments are NIL !!")
            return
        }

        for elem in attachments {
            if elem.hasItemConformingToTypeIdentifier("public.plain-text") {
                loadPlainText(elem: elem)
            } else if elem.hasItemConformingToTypeIdentifier("public.image") {
                loadImage(elem: elem)
            } else if elem.hasItemConformingToTypeIdentifier("public.file-url") {
                loadFile(elem: elem)
            }
            Log.shared.logInfo(message: "DEV: elem \(elem)")
        }

    }

    private func loadPlainText(elem: NSItemProvider) {
        elem.loadItem(forTypeIdentifier: "public.plain-text", options: nil, completionHandler: { [weak self] item, error in

            guard let me = self else {
                // assuming the extension can be canceled by the user
                return
            }

            if let text = item as? String {
                DispatchQueue.main.async {
                    // TODO: Inform compose about a text attachment?
                }
            }
        })
    }

    private func loadImage(elem: NSItemProvider) {
        elem.loadItem(forTypeIdentifier: "public.jpeg", options: nil, completionHandler: { [weak self] item, error in

            guard let me = self else {
                // assuming the extension can be canceled by the user
                return
            }

            if let imgUrl = item as? URL,
               let imgData = try? Data(contentsOf: imgUrl),
               let img = UIImage(data: imgData) {
                DispatchQueue.main.async {
                    // TODO: Inform compose about an image to attach
                    print("*** composeViewController \(me.composeViewController)")
                }
            }

        })
    }

    private func loadFile(elem: NSItemProvider) {
        // TODO: - not yet implemented
        Log.shared.debug("DEV: load PDF element is not yet implemented!")
    }
}
