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
    var segueTrustWords = "segueTrustWords"


    override func viewDidLoad() {
        super.viewDidLoad()
        UIHelper.variableCellHeightsTableView(self.tableView)
        firstReload = true
        if let m = self.message {
            allRecipients = m.allRecipienst()
        }
        self.navigationController?.toolbar.hidden = true

        print (" ALL CONTACT:")
        for contact in allRecipients! {
            let contactAux = contact as! Contact
            let name = contactAux.displayString()
            print (name)
        }
       /* if let m = message {
            let recipients = m.allRecipienst()
            for contact in recipients {
                var contactString = contact.displayString
                stringRecipients.append(contact.displayString())
            }
        }*/
        
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
                let mailPepColor = m.pepColor.integerValue
                if let pc = PEPUtil.pepColorRatingFromInt(mailPepColor) {
                    let privateColor = PEPUtil.abstractPepColorFromPepColor(pc)
                    if let uiColor = paintingMailStatus(privateColor) {
                        cell.backgroundColor = uiColor
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
                let mailPepColor = m.pepColor.integerValue
                if let pepColor = PEPUtil.pepColorRatingFromInt(mailPepColor) {
                    cell.mailExplanationSecurityUILabel.text = PEPUtil.pepExplanationToHash(pepColor)
                }
            }
            return cell
        }
        let cell = tableView.dequeueReusableCellWithIdentifier("trustwordsCell",
                                                           forIndexPath: indexPath) as! TrustWordsViewCell
            if let allContact = allRecipients {
                print ("INDEX:\(indexPath.row)")
                let index = indexPath.row - 2
                print ("INDEX - 2 :\(index)")
                let contact :Contact  = allContact[indexPath.row-2] as! Contact
                cell.handshakeContactUILabel.text = contact.displayString()
                 print ("CONTACT: \(contact)")
                if contact.name == nil {
                    contact.name = "TOFU"
                }
                let pepColor = PEPUtil.colorRatingForContact(contact)
                let privateColor = PEPUtil.abstractPepColorFromPepColor(pepColor)
                cell.backgroundColor = paintingMailStatus(privateColor)
            }
        return cell
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == segueTrustWords) {
            let destination = segue.destinationViewController
                as? DetailTrustWordsViewCell;
            destination?.message = self.message
        }
    }
}
