//
//  HandshakeViewController.swift
//  pEpForiOS
//
//  Created by ana on 21/7/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

extension String {
    func insert(string:String,ind:Int) -> String {
        return  String(self.characters.prefix(ind)) + string + String(self.characters.suffix(self.characters.count-ind))
    }
}

class HandshakeViewController: UITableViewController, UIGestureRecognizerDelegate {

    var message: IMessage?
    var partner: Contact?
    var appConfig: AppConfig!
    var hexamode: Bool = false

    let myselfLabel = 0
    let myselfContact = 1
    let partnerLabel = 2
    let partnerContact = 3
    let explanationTrustwords = 4
    let trustwords = 5
    let confirmButton = 6

    override func viewDidLoad() {
        super.viewDidLoad()
        UIHelper.variableCellHeightsTableView(tableView)
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
        //let cell = UITableViewCell();
        if (indexPath.row == myselfLabel) {
            let cell = tableView.dequeueReusableCellWithIdentifier("contactCell", forIndexPath: indexPath) as! HandshakeLabelTableViewCell
            cell.handshakeLabel.text = "Myself:"
            return cell
        } else if (indexPath.row == myselfContact) {
            let cell = tableView.dequeueReusableCellWithIdentifier("contactCell", forIndexPath: indexPath) as! HandshakeLabelTableViewCell
            let myselfEmail = appConfig.currentAccount!.email
            cell.handshakeLabel.text = myselfEmail
            return cell
        } else if (indexPath.row == partnerLabel) {
            let cell = tableView.dequeueReusableCellWithIdentifier("contactCell", forIndexPath: indexPath) as! HandshakeLabelTableViewCell
            cell.handshakeLabel.text = "Partner:"
            return cell
        } else if (indexPath.row == partnerContact) {
            let cell = tableView.dequeueReusableCellWithIdentifier("contactCell", forIndexPath: indexPath) as! HandshakeLabelTableViewCell
            cell.handshakeLabel.text = partner!.displayString()
            return cell
        } else if (indexPath.row == explanationTrustwords) {
            let cell = tableView.dequeueReusableCellWithIdentifier("trustwordCell", forIndexPath: indexPath) as! HandshakeTexViewTableViewCell
            cell.handshakeTextView.text = "Ask your partner: What are your trustword? then compare to the correct answer shown below."
            return cell
        } else if (indexPath.row == trustwords) {

            let cell = tableView.dequeueReusableCellWithIdentifier("trustwordCell", forIndexPath: indexPath) as! HandshakeTexViewTableViewCell
            if let p = partner {
                let partnerPepContact = PEPUtil.pepContact(p)
                let myselfEmail = appConfig.currentAccount!.email
                let myselfContact = appConfig.model.contactByEmail(myselfEmail)
                if let m = myselfContact {
                    let myselfContactPepContact = PEPUtil.pepContact(m)
                    let recognizer = UITapGestureRecognizer(target: self, action:#selector(HandshakeViewController.handleTap(_:)))
                    recognizer.delegate = self
                    cell.handshakeTextView.addGestureRecognizer(recognizer)
                    if !hexamode {
                        cell.handshakeTextView.text = PEPUtil.trustwordsForIdentity1(
                        myselfContactPepContact, identity2: partnerPepContact,
                        language: "en", session: nil)
                    } else {
                        let myselfFingerprints = PEPUtil.fingprprintForContact(myselfContact!)
                        let partnerFingerprints = PEPUtil.fingprprintForContact(partner!)
                        let bothFingerprints = "\(partnerFingerprints!) \n \(myselfFingerprints!)"
                        cell.handshakeTextView.text = bothFingerprints
                    }
                }
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("handshakeButton", forIndexPath: indexPath) as! HandshakeButtonTableViewCell
            cell.confirmUIButton.setTitle("Confirm trustwords", forState: UIControlState.Normal)
            cell.deniedUIButton.setTitle("Wrong trustwords", forState: UIControlState.Normal)
            return cell

        }
    }

    @IBAction func handleTap(sender: UITapGestureRecognizer) {
        hexamode = !hexamode
        self.tableView.reloadData()
    }
}

