//
//  HandshakeViewController.swift
//  pEpForiOS
//
//  Created by ana on 21/7/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit



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
            cell.handshakeLabel.text = NSLocalizedString("Myself:", comment: "Myself label, handshake")
            return cell
        } else if (indexPath.row == myselfContact) {
            let cell = tableView.dequeueReusableCellWithIdentifier("contactCell", forIndexPath: indexPath) as! HandshakeLabelTableViewCell
            let myselfEmail = appConfig.currentAccount!.email
            cell.handshakeLabel.text = myselfEmail
            return cell
        } else if (indexPath.row == partnerLabel) {
            let cell = tableView.dequeueReusableCellWithIdentifier("contactCell", forIndexPath: indexPath) as! HandshakeLabelTableViewCell
            cell.handshakeLabel.text = NSLocalizedString("Partner:", comment: "Partner label, handshake")
            return cell
        } else if (indexPath.row == partnerContact) {
            let cell = tableView.dequeueReusableCellWithIdentifier("contactCell", forIndexPath: indexPath) as! HandshakeLabelTableViewCell
            cell.handshakeLabel.text = partner!.displayString()
            return cell
        } else if (indexPath.row == explanationTrustwords) {
            let cell = tableView.dequeueReusableCellWithIdentifier("trustwordCell", forIndexPath: indexPath) as! HandshakeTexViewTableViewCell
            cell.handshakeTextView.text = NSLocalizedString("Ask your partner: What are your trustword? then compare to the correct answer shown below.", comment: "Handshake explanation")
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
                        let bothFingerprints = "\(fingerprintFormat(partnerFingerprints!))\n\n\(fingerprintFormat(myselfFingerprints!))"
                        cell.handshakeTextView.text = bothFingerprints
                        cell.handshakeTextView.font = UIFont(name: "Menlo", size: UIFont.systemFontSize())
                    }
                }
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("handshakeButton", forIndexPath: indexPath) as! HandshakeButtonTableViewCell
            cell.confirmUIButton.setTitle(NSLocalizedString("Confirm trustwords", comment: "confirm button, handshake"), forState: UIControlState.Normal)
            cell.confirmUIButton.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
            cell.confirmUIButton.imageEdgeInsets = UIEdgeInsetsMake(0, -20, 0, 0)
            cell.deniedUIButton.setTitle(NSLocalizedString("Wrong trustwords", comment: "wrong trustwords button, handshake"), forState: UIControlState.Normal)
            cell.deniedUIButton.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
            cell.deniedUIButton.imageEdgeInsets = UIEdgeInsetsMake(0, -20, 0, 0)
            return cell
        }
    }

    func fingerprintFormat(fingerprint: String) -> String {
        let medio = fingerprint.characters.count/2
        var result = String()
        var cont = 0
        for character in fingerprint.characters {
            cont += 1
            result.append(character)
            if cont % 4 == 0 {
                result.append(" " as Character)
                result.append(" " as Character)
            }
            if cont == medio {
                result.append("\n" as Character)
            }
        }
        return result
    }

    @IBAction func confirmTrustwords(sender: AnyObject) {
        if let p = partner {
            PEPUtil.trustContact(p)
            navigationController?.popViewControllerAnimated(true)
        }
    }

    @IBAction func wrongTrustwords(sender: AnyObject) {
        if let p = partner {
            PEPUtil.mistrustContact(p)
            navigationController?.popViewControllerAnimated(true)
        }
    }

    @IBAction func handleTap(sender: UITapGestureRecognizer) {
        hexamode = !hexamode
        self.tableView.reloadData()
    }
}

