//
//  ComposeTableViewController.swift
//  pEp-share
//
//  Created by Adam Kowalski on 14/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

final class ComposeTableViewController: UITableViewController {

    @IBOutlet weak var bodyTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    func addImage(image: UIImage) {

        var imageThumb = image

        if image.size.width > UIScreen.main.bounds.width {
            let aspectRatio = image.size.width / image.size.height
            if let imageResized = image.resizeImage(targetSize: CGSize(width: UIScreen.main.bounds.width,
                                                                     height: UIScreen.main.bounds.width * aspectRatio)) {
                imageThumb = imageResized
            }
        }

        let attachment = NSTextAttachment()
        attachment.image = imageThumb
        let aStringWithAttachment = NSAttributedString(attachment: attachment)

        let aMutableString = NSMutableAttributedString(attributedString: bodyTextView.attributedText)
        aMutableString.append(aStringWithAttachment)
        let aString = NSAttributedString(attributedString: aMutableString)
        bodyTextView.attributedText = aString
    }

    func addPlainText(text: String) {
        bodyTextView.insertText(text)
    }

}
