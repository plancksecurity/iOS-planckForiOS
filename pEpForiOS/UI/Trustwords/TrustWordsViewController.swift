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


    override func viewDidLoad() {
        super.viewDidLoad()
        UIHelper.variableCellHeightsTableView(self.tableView)
        firstReload = true
        
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
            return allContact.count
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
            let cell = tableView.dequeueReusableCellWithIdentifier("mailSecurityExplanationLabelCell", forIndexPath: indexPath) as!
            LabelMailExplantionSecurityTableViewCell
            if let m = message {
                let mailPepColor = m.pepColor.integerValue
                if let pepColor = PEPUtil.pepColorRatingFromInt(mailPepColor) {
                    cell.mailExplanationSecurityUILabel.text = PEPUtil.pepExplanationToHash(pepColor)
                }
            }
            return cell
        }
    let cell = tableView.dequeueReusableCellWithIdentifier("trustwordsCell", forIndexPath: indexPath) as! TrustWordsViewCell
            if let allContact = allRecipients {
                let contact :Contact  = allContact[indexPath.row] as! Contact
                cell.handshakeContactUILabel.text = contact.displayString()
                let pepColor = PEPUtil.colorRatingForContact(contact)
                let privateColor = PEPUtil.abstractPepColorFromPepColor(pepColor)
                cell.backgroundColor = paintingMailStatus(privateColor)
            }
        return cell
    }


}
