//
//  TrustwordViewController.swift
//  pEpForiOS
//
//  Created by ana on 7/7/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class TrustWordsViewController: UITableViewController {
    var appConfig: AppConfig!
    var message: IMessage?

    /** All recipients to be able to do a handshake */
    var allRecipientsFiltered = [IContact]()

    /** A set of accounts from the same user on the device with another email */
    var otherMyselfAccount = NSMutableSet()

    var firstReload = true

    /** The default background color of a fresh cell */
    var defaultBackground: UIColor?

    let handshakeSegue = "handshakeSegue"
    let numberOfStaticCells = 2

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()

        let allRecipients: NSMutableOrderedSet?

        otherMyselfAccount.removeAllObjects()
        allRecipientsFiltered.removeAll()
        UIHelper.variableCellHeightsTableView(self.tableView)
        if let m = self.message {
            allRecipients = m.allRecipienst().mutableCopy() as? NSMutableOrderedSet
            if let ar = allRecipients {
                if let f = m.from {
                    ar.addObject(f)
                }
                for contact in ar {
                    if let c = contact as? IContact {
                        if c.isMySelf.boolValue {
                            if appConfig.currentAccount?.email != c.email {
                                allRecipientsFiltered.append(c)
                                otherMyselfAccount.addObject(c)
                            }
                        } else {
                            allRecipientsFiltered.append(c)
                        }
                    }
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let lenght = allRecipientsFiltered.count + numberOfStaticCells
        return lenght
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (indexPath.row == 0) {
            let cell = tableView.dequeueReusableCellWithIdentifier("mailSecurityLabelCell", forIndexPath: indexPath) as!
            LabelMailSecurityTableViewCell

            // Store the background color if this is the first cell
            if (firstReload) {
                defaultBackground = cell.backgroundColor
                firstReload = false
            }

            if let m = message {
                cell.backgroundColor = defaultBackground
                if let mailPepColor = m.pepColorRating?.integerValue {
                    if let pc = PEPUtil.colorRatingFromInt(mailPepColor) {
                        let privateColor = PEPUtil.colorFromPepRating(pc)
                        if let uiColor = UIHelper.trustWordsCellBackgroundColorFromPepColor(
                            privateColor) {
                            cell.backgroundColor = uiColor
                        }
                        let securityTitleText = PEPUtil.pepTitleFromColor(pc)
                        let lenghtOfSecurityLabel = securityTitleText?.characters.count
                        let attributedString = NSMutableAttributedString(string:securityTitleText!)
                        attributedString.addAttribute(NSLinkAttributeName, value: "https://", range: NSRange(location: 0, length: lenghtOfSecurityLabel!))
                        cell.mailSecurityUILabel.attributedText = attributedString
                    }
                }
            }
            return cell
        } else if (indexPath.row == 1) {
            let cell = tableView.dequeueReusableCellWithIdentifier(
                "mailSecurityExplanationLabelCell", forIndexPath: indexPath) as!
            LabelMailExplantionSecurityTableViewCell

            cell.mailExplanationSecurityUILabel.text = ""
            if let m = message {
                if let mailPepColor = m.pepColorRating?.integerValue {
                    if let pepColor = PEPUtil.colorRatingFromInt(mailPepColor) {
                        cell.mailExplanationSecurityUILabel.text =
                            PEPUtil.pepExplanationFromColor(pepColor)
                    }
                }
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("trustwordsCell",
                                                           forIndexPath: indexPath) as! TrustWordsViewCell
            let contactIndex = indexPath.row-numberOfStaticCells
            let contact: Contact  = allRecipientsFiltered[contactIndex] as! Contact

            cell.handshakeContactUILabel.text = contact.displayString()
            cell.handshakeUIButton.tag = contactIndex
            let privacyColor = PEPUtil.privacyColorForContact(contact)
            cell.backgroundColor = UIHelper.trustWordsCellBackgroundColorFromPepColor(
                privacyColor)

            cell.handshakeUIButton.enabled = !otherMyselfAccount.containsObject(contact)

            switch privacyColor {
            case PEP_color_red:
                cell.handshakeUIButton.setTitle(
                    NSLocalizedString("Trust Again", comment: "handshake red"), forState: .Normal)
            case PEP_color_green:
                cell.handshakeUIButton.setTitle(
                    NSLocalizedString("Reset trust", comment: "handshake green"), forState: .Normal)
            case PEP_color_yellow:
                cell.handshakeUIButton.setTitle(
                    NSLocalizedString("Handshake", comment: "handshake yellow"), forState: .Normal)
            default:
                cell.handshakeUIButton.enabled = false
            }
            return cell
        }
    }

    func showErrorMessage (message: String) {
        let alertView = UIAlertController(
            title: NSLocalizedString("Suggestion",comment: "Suggestion tittle"),
            message:NSLocalizedString(message, comment: "Suggestion"), preferredStyle: .Alert)
        alertView.addAction(UIAlertAction(
            title: NSLocalizedString("Ok",comment: "confirm  button text"),
            style: .Default, handler: nil))
        presentViewController(alertView, animated: true, completion: nil)
    }

    @IBAction func showMoreInfo(sender: AnyObject) {
        if let m = message {
            if let mailPepColor = m.pepColorRating?.integerValue {
                if let pepColor = PEPUtil.colorRatingFromInt(mailPepColor) {
                    if let suggestion = PEPUtil.pepSuggestionFromColor(pepColor) {
                        self.showErrorMessage(suggestion)
                    }
                }
            }
        }
    }

    @IBAction func goToHandshakeScreen(sender: AnyObject) {
        let contactIndex = sender.tag
        let contact = allRecipientsFiltered[contactIndex]
        let pepColor = PEPUtil.privacyColorForContact(contact)
        if pepColor == PEP_color_red || pepColor == PEP_color_green {
            PEPUtil.resetTrustForContact(contact)
            self.tableView.reloadData()
        } else {
            performSegueWithIdentifier(handshakeSegue, sender: sender)
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == handshakeSegue) {
            let contactIndex = sender.tag
            let contact = allRecipientsFiltered[contactIndex] as! Contact
            if let destination = segue.destinationViewController as? HandshakeViewController {
                destination.partner = contact
                destination.appConfig = appConfig
                destination.message = message
            }
        }
    }
}