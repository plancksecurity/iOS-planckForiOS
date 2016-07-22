//
//  VerboseTrustWordViewController.swift
//  pEpForiOS
//
//  Created by ana on 21/7/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class HandshakeViewController: UIViewController, UITextViewDelegate {

    var message: Message?
    
    @IBOutlet weak var trustwordsUITextView: UITextView!
    @IBOutlet weak var myselfUILabel: UILabel!
    @IBOutlet weak var partnerUILabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.trustwordsUITextView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        textView.resignFirstResponder()
        textView.text = "0X23434 0X123424"
        return true
    }
}

