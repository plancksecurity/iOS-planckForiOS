//
//  ShareViewController.swift
//  pEp-share
//
//  Created by Adam Kowalski on 15/05/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit
import Social

final class ShareViewController: UIViewController {

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

    //    override func isContentValid() -> Bool {
//        // Do validation of contentText and/or NSExtensionContext attachments here
//        return true
//    }
//
//    override func didSelectPost() {
//        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
//
//        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
//        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
//    }
//
//    override func configurationItems() -> [Any]! {
//        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
//        return []
//    }

}

// MARK: - Private (WIP)

extension ShareViewController {
    private func checkInputItems() {

        guard let context = extensionContext else {
            print("DEV: extensionContext is NIL !!")
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
}
