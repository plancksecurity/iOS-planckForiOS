//
//  ShareViewController.swift
//  pEp-share
//
//  Created by Adam Kowalski on 14/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel
import pEpIOSToolbox

final class ShareViewController: UIViewController {

    private var messageModelService: MessageModelServiceProtocol?

    var composeTableVC: ComposeTableViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        checkInputItems()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ComposeTableViewController {
            composeTableVC = vc
        }

    }

    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}

// MARK: - Private (WIP)

extension ShareViewController {
    private func checkInputItems() {

        // TODO: Send the mail
        //let sendMail = SendMailHelper.shared
        //sendMail.sendMessage()

        guard let context = extensionContext else {
            Log.shared.errorAndCrash(message: "Lost extension context!")
            return
        }

        guard let item = context.inputItems.first as? NSExtensionItem,
              let attachments = item.attachments else {
            print("DEV: attachments are NIL !!")
            return
        }

        for elem in attachments {
            if elem.hasItemConformingToTypeIdentifier("public.plain-text") {
                loadPlainText(elem: elem)
            } else if elem.hasItemConformingToTypeIdentifier("public.jpeg") {
                loadImage(elem: elem)
            } else if elem.hasItemConformingToTypeIdentifier("public.file-url") {
                loadFile(elem: elem)
            }
            print("DEV: elem \(elem)")
        }

    }

    private func loadPlainText(elem: NSItemProvider) {
        elem.loadItem(forTypeIdentifier: "public.plain-text", options: nil, completionHandler: { [weak self] item, error in

            guard let me = self else { return }

            if let text = item as? String {
                DispatchQueue.main.async {
                    me.composeTableVC?.addPlainText(text: text)
                }
            }
        })
    }

    private func loadImage(elem: NSItemProvider) {
        elem.loadItem(forTypeIdentifier: "public.jpeg", options: nil, completionHandler: { [weak self] item, error in

            guard let me = self else { return }

            if let imgUrl = item as? URL,
               let imgData = try? Data(contentsOf: imgUrl),
               let img = UIImage(data: imgData) {
                DispatchQueue.main.async {
                    me.composeTableVC?.addImage(image: img)
                }
            }

        })
    }

    private func loadFile(elem: NSItemProvider) {
        // TODO: - not yet implemented
        print("DEV: load PDF element is not yet implemented!")
    }
}
