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
                let pepColor: PEP_color = PEPUtil.pepColorRatingFromInt(mailPepColor)
                let privateColor = PEPUtil.abstractPepColorFromPepColor(pepColor)
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
            cell.mailSecurityUILabel.text = "hola"
            return cell
        }
        let cell = tableView.dequeueReusableCellWithIdentifier("trustwordsCell", forIndexPath: indexPath) as! TrustWordsViewCell
            if let allContact = allRecipients {
                let contact :Contact  = allContact[indexPath.row] as! Contact
                cell.handshakeContactUILabel.text = contact.displayString()
            }
        return cell
    }



    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
