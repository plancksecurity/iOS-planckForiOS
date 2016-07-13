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
    }

    func paintingMailStatus(privateColor: PrivacyColor) -> UIColor {
        switch privateColor.hashValue {
        case 0:
            return UIColor.greenColor()
        case 1:
            return  UIColor.yellowColor()
        case 2:
            return  UIColor.redColor()
        default:
              return UIColor.redColor()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let allContact = allRecipients {
            return allContact.count
        }
        return 4
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (indexPath.row == 0) {
             let cell = tableView.dequeueReusableCellWithIdentifier("mailSecurityLabelCell", forIndexPath: indexPath) as! LabelMailSecurityTableViewCell
            if let colorMessage = message {
                let mailPepColor = colorMessage.pepColor.integerValue
                let pepColor = PEPUtil.pepColorRatingFromInt(mailPepColor)
                let privateColor = PEPUtil.abstractPepColorFromPepColor(pepColor)
                let uiColor = paintingMailStatus(privateColor)
                cell.backgroundColor = uiColor
            }
            cell.mailSecurityUILabel.text = "hola"
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
