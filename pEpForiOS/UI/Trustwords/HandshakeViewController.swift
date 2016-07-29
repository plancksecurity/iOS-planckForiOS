//
//  HandshakeViewController.swift
//  pEpForiOS
//
//  Created by ana on 21/7/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class HandshakeViewController: UITableViewController {
//, UITextViewDelegate {

    var message: Message?
    var partner: Contact?
    var appConfig: AppConfig!

   //var myselfPepContact = PEPUtil.pepContact(myselfContact)


    override func viewDidLoad() {
        super.viewDidLoad()
        UIHelper.variableCellHeightsTableView(tableView)
        /*self.trustwordsUITextView.delegate = self
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
        }*/
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let myselfLabel = 0
        let myselfContact = 1
        let partnerLabel = 2
        let partnerContact = 3
        let explanationTrustwords = 4
        let trustwords = 5

        if (indexPath.row < 4) {
            let cell = tableView.dequeueReusableCellWithIdentifier("contactCell", forIndexPath: indexPath) as! HandshakeLabelTableViewCell
            if (indexPath.row == myselfLabel) {
                cell.handshakeLabel.text = "Partner"
            } else if (indexPath.row == myselfContact) {
                cell.handshakeLabel.text = "ana@gmail.com"
            } else if (indexPath.row == partnerLabel) {
                cell.handshakeLabel.text = "Myself"
            } else if (indexPath.row == partnerContact) {
                cell.handshakeLabel.text = "ana@gmail.com"
            }
              return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("trustwordCell", forIndexPath: indexPath) as! HandshakeTexViewTableViewCell
            if (indexPath.row == explanationTrustwords) {
                cell.handshakeTextView.text = "Ask your partner: What are your trustword? then compare to the correct answer shown below."
            }
            if (indexPath.row == trustwords) {
                cell.handshakeTextView.text = "ENQQQQNNNNQNQNQNNQNQNQNQNNQNQNQNQNQNNQNQNQN"
            }
            return cell
        }

    }


   /*override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (indexPath.row == 0) {
            let cell = tableView.dequeueReusableCellWithIdentifier("mailSecurityLabelCell", forIndexPath: indexPath) as! LabelMailSecurityTableViewCell
            if let m = message {
                // default
                if (firstReload) {
                    defaultBackground = cell.backgroundColor
                    firstReload = false
                }
                cell.backgroundColor = defaultBackground
                if let mailPepColor = m.pepColorRating?.integerValue {
                    if let pc = PEPUtil.pepColorRatingFromInt(mailPepColor) {
                        let privateColor = PEPUtil.colorFromPepColorRating(pc)
                        if let uiColor = paintingMailStatus(privateColor) {
                            cell.backgroundColor = uiColor
                        }
                    }
                }
            }
            cell.mailSecurityUILabel.text = "hola"
            return cell
        }
        if (indexPath.row == 1) {
            let cell = tableView.dequeueReusableCellWithIdentifier(
                "mailSecurityExplanationLabelCell", forIndexPath: indexPath) as!
            LabelMailExplantionSecurityTableViewCell

            if let m = message {
                if let mailPepColor = m.pepColorRating?.integerValue {
                    if let pepColor = PEPUtil.pepColorRatingFromInt(mailPepColor) {
                        cell.mailExplanationSecurityUILabel.text =
                            PEPUtil.pepExplanationFromColor(pepColor)

                    }
                }
            }
            return cell
        }
        let cell = tableView.dequeueReusableCellWithIdentifier("trustwordsCell",
                                                               forIndexPath: indexPath) as! TrustWordsViewCell
        if let allContact = allRecipients {
            let _ = indexPath.row - 2
            let contact :Contact  = allContact[indexPath.row-2] as! Contact
            cell.handshakeContactUILabel.text = contact.displayString()
            cell.handshakeUIButton.tag = indexPath.row
            let pepColor = PEPUtil.colorRatingForContact(contact)
            let privateColor = PEPUtil.colorFromPepColorRating(pepColor)
            cell.backgroundColor = paintingMailStatus(privateColor)
        }
        return cell
    }*/


    /*func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        textView.resignFirstResponder()
        textView.text = "0X23434 0X123424"
        return true
    }*/
}

