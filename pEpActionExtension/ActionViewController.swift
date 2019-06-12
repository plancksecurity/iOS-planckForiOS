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
//                Log.shared.errorAndCrash("%@",
//                        ActionExtentionErrors.failToShareNoNSExtensionItem.localizedDescription)
            return
        }

        for item in inputItems {
            guard let attachments = item.attachments else {
                continue
            }
            for attachment in attachments {
                
//                if provider.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
//                    // This is an image. We'll load it, then place it in our image view.
//                    weak var weakImageView = self.imageView
//                    provider.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil, completionHandler: { (imageURL, error) in
////                        OperationQueue.main.addOperation {
////                            if let strongImageView = weakImageView {
////                                if let imageURL = imageURL as? URL {
////                                    strongImageView.image = UIImage(data: try! Data(contentsOf: imageURL))
////                                }
////                            }
//                        }
//                    })
//                    
//                    imageFound = true
//                    break
//                }
            }
            
//            if (imageFound) {
//                // We only handle one image, so stop looking for more.
//                break
//            }
        }
        extensionContext.completeRequest(returningItems: extensionContext.inputItems, completionHandler: nil)
    }

//    func done() {
//        // Return any edited content to the host app.
//        // This template doesn't do anything, so we just echo the passed in items.
//        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
//    }

}
