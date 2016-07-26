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
    var partner: Contact?
    var appConfig: AppConfig!

   //var myselfPepContact = PEPUtil.pepContact(myselfContact)
    
    @IBOutlet weak var trustwordsUITextView: UITextView!
    @IBOutlet weak var myselfUILabel: UILabel!
    @IBOutlet weak var partnerUILabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.trustwordsUITextView.delegate = self
        if let p = partner {
            let partnerPepContact = PEPUtil.pepContact(p)
            let myselfEmail = appConfig.currentAccount!.email
            let myselfContact = appConfig.model.contactByEmail(myselfEmail)
            if let m = myselfContact {
                let myselfContactPepContact = PEPUtil.pepContact(m)
                myselfUILabel.text = myselfEmail
                partnerUILabel.text = p.displayString()
                trustwordsUITextView.text = PEPUtil.trustwordsForIdentity1(
                    myselfContactPepContact, identity2: partnerPepContact,
                    language: "en", session: nil)
            }
        }
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

