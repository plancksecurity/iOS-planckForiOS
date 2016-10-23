//
//  TrustwordViewController.swift
//  pEpForiOS
//
//  Created by ana on 7/7/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

class TrustWordsViewController: UITableViewController {
    var appConfig: AppConfig!
    var message: Message?

    /** All recipients to be able to do a handshake */
    var allRecipientsFiltered = [CdContact]()

    /** A set of accounts from the same user on the device with another email */
    var otherMyselfAccount = NSMutableSet()

    var firstReload = true

    /** The default background color of a fresh cell */
    var defaultBackground: UIColor?

    let handshakeSegue = "handshakeSegue"
    let numberOfStaticCells = 2

    override func viewWillAppear(_ animated: Bool) {
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
                    ar.add(f)
                }
                for contact in ar {
                    if let c = contact as? CdContact {
                        if c.isMySelf.boolValue {
                            if appConfig.currentAccount?.user.address != c.email {
                                allRecipientsFiltered.append(c)
                                otherMyselfAccount.add(c)
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

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let lenght = allRecipientsFiltered.count + numberOfStaticCells
        return lenght
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if ((indexPath as NSIndexPath).row == 0) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "mailSecurityLabelCell", for: indexPath) as!
            LabelMailSecurityTableViewCell

            // Store the background color if this is the first cell
            if (firstReload) {
                defaultBackground = cell.backgroundColor
                firstReload = false
            }

            if let m = message {
                cell.backgroundColor = defaultBackground
                if let mailPepColor = m.pepColorRating?.intValue {
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
        } else if ((indexPath as NSIndexPath).row == 1) {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "mailSecurityExplanationLabelCell", for: indexPath) as!
            LabelMailExplantionSecurityTableViewCell

            cell.mailExplanationSecurityUILabel.text = ""
            if let m = message {
                if let mailPepColor = m.pepColorRating?.intValue {
                    if let pepColor = PEPUtil.colorRatingFromInt(mailPepColor) {
                        cell.mailExplanationSecurityUILabel.text =
                            PEPUtil.pepExplanationFromColor(pepColor)
                    }
                }
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "trustwordsCell",
                                                           for: indexPath) as! TrustWordsViewCell
            let contactIndex = (indexPath as NSIndexPath).row-numberOfStaticCells
            let contact: CdContact  = allRecipientsFiltered[contactIndex]

            cell.handshakeContactUILabel.text = contact.displayString()
            cell.handshakeUIButton.tag = contactIndex
            let privacyColor = PEPUtil.privacyColorForContact(contact)
            cell.backgroundColor = UIHelper.trustWordsCellBackgroundColorFromPepColor(
                privacyColor)

            cell.handshakeUIButton.isEnabled = !otherMyselfAccount.contains(contact)

            switch privacyColor {
            case PEP_color_red:
                cell.handshakeUIButton.setTitle(
                    NSLocalizedString("Trust Again", comment: "handshake red"), for: UIControlState())
            case PEP_color_green:
                cell.handshakeUIButton.setTitle(
                    NSLocalizedString("Reset trust", comment: "handshake green"), for: UIControlState())
            case PEP_color_yellow:
                cell.handshakeUIButton.setTitle(
                    NSLocalizedString("Handshake", comment: "handshake yellow"), for: UIControlState())
            default:
                cell.handshakeUIButton.isEnabled = false
            }
            return cell
        }
    }

    func showSuggestionMessage (_ message: String) {
        // Abuse error display
        UIHelper.displayErrorMessage(
            message, controller: self,
            title: NSLocalizedString("pEp",comment: "Suggestion tittle"))
    }

    @IBAction func showMoreInfo(_ sender: AnyObject) {
        if let m = message {
            if let mailPepColor = m.pepColorRating?.intValue {
                if let pepColor = PEPUtil.colorRatingFromInt(mailPepColor) {
                    if let suggestion = PEPUtil.pepSuggestionFromColor(pepColor) {
                        self.showSuggestionMessage(suggestion)
                    }
                }
            }
        }
    }

    @IBAction func goToHandshakeScreen(_ sender: AnyObject) {
        let contactIndex = sender.tag
        let contact = allRecipientsFiltered[contactIndex!]
        let pepColor = PEPUtil.privacyColorForContact(contact)
        if pepColor == PEP_color_red || pepColor == PEP_color_green {
            PEPUtil.resetTrustForContact(contact)
            self.tableView.reloadData()
        } else {
            performSegue(withIdentifier: handshakeSegue, sender: sender)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if (segue.identifier == handshakeSegue) {
            let contactIndex = (sender as AnyObject).tag
            let contact = allRecipientsFiltered[contactIndex!]
            if let destination = segue.destination as? HandshakeViewController {
                destination.partner = contact
                destination.appConfig = appConfig
                destination.message = message
            }
        }
    }
}
