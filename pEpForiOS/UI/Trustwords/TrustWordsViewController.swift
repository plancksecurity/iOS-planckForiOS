//
//  TrustwordViewController.swift
//  pEpForiOS
//
//  Created by ana on 7/7/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class TrustWordsViewController: UITableViewController {

    var allRecipients: NSOrderedSet?
    var message: Message?
    var firstReload = true
    var defaultBackground: UIColor?
    var stringRecipients:[String]!
    var handshakeSegue = "handshakeSegue"
    var appConfig: AppConfig!


    override func viewDidLoad() {
        super.viewDidLoad()
        UIHelper.variableCellHeightsTableView(self.tableView)
        firstReload = true
        if let m = self.message {
            allRecipients = m.allRecipienst()
        }
    }

    func paintingMailStatus(privateColor: PrivacyColor) -> UIColor? {
        switch privateColor {
        case .Green:
            return UIColor.greenColor()
        case .Yellow:
            return  UIColor.yellowColor()
        case .Red:
            return  UIColor.redColor()
        case .NoColor:
            return nil
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let allContact = allRecipients {
            let lenght = allContact.count + 2
            return lenght
        }
        return 2
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
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
                    if let pc = PEPUtil.colorRatingFromInt(mailPepColor) {
                        let privateColor = PEPUtil.privacyColorFromPepColorRating(pc)
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
                    if let pepColor = PEPUtil.colorRatingFromInt(mailPepColor) {
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
                let contact: Contact  = allContact[indexPath.row-2] as! Contact
                cell.handshakeContactUILabel.text = contact.displayString()
                cell.handshakeUIButton.tag = indexPath.row
                let privacyColor = PEPUtil.privacyColorForContact(contact)
                cell.backgroundColor = paintingMailStatus(privacyColor)
            }
        return cell
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == handshakeSegue) {
            let index = sender.tag
            if let  allRecipientsAux = allRecipients {
                let contact = allRecipientsAux[index-2] as! Contact
                if let destination = segue.destinationViewController as? HandshakeViewController {
                    destination.partner = contact
                    destination.appConfig = appConfig
                    destination.message = message
            }
            }
        }
    }


}
