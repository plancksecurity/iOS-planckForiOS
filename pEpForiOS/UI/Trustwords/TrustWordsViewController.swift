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

    override func viewDidLoad() {
        super.viewDidLoad()
        UIHelper.variableCellHeightsTableView(self.tableView)
        
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
                let mailPepColor = m.pepColor.integerValue
                let pepColor = PEPUtil.pepColorRatingFromInt(mailPepColor)
                if let pc = pepColor {
                    let privateColor = PEPUtil.abstractPepColorFromPepColor(pc)
                    if let c = privateColor {
                        let uiColor = paintingMailStatus(c)
                        if let uic = uiColor {
                            cell.backgroundColor = uic
                        }
                    } else {
                        let defaultLabel = UILabel()
                        defaultLabel.text = "temp"
                        cell.backgroundColor = defaultLabel.backgroundColor
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
            }
        return cell
    }


}
