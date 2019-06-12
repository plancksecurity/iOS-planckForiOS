//
//  ActionViewController.swift
//  pEpActionExtension
//
//  Created by Alejandro Gelos on 31/05/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit
import MobileCoreServices

class ActionViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Get the item[s] we're handling from the extension context.
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            return
        }
        AttachmentsUtils.attachmentsURL(inputItems: inputItems, completion: { result in
            switch result {
            case .failure(let error):
                break
            case .success(let urls):
                print(urls)
            }
        })
        extensionContext.completeRequest(returningItems:
                            extensionContext.inputItems, completionHandler: nil)
    }
}
