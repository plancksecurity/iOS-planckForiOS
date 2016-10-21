//
//  HandshakeViewController.swift
//  pEpForiOS
//
//  Created by ana on 21/7/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class HandshakeViewController: UITableViewController, UIGestureRecognizerDelegate {
    var message: CdMessage?
    var partner: CdContact?
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

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //let cell = UITableViewCell();
        if ((indexPath as NSIndexPath).row == myselfLabel) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "contactCell", for: indexPath) as! HandshakeLabelTableViewCell
            cell.handshakeLabel.text = NSLocalizedString("Myself:", comment: "Myself label, handshake")
            return cell
        } else if ((indexPath as NSIndexPath).row == myselfContact) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "contactCell", for: indexPath) as! HandshakeLabelTableViewCell
            let myselfEmail = appConfig.currentAccount?.user.address ?? ""
            cell.handshakeLabel.text = myselfEmail
            return cell
        } else if ((indexPath as NSIndexPath).row == partnerLabel) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "contactCell", for: indexPath) as! HandshakeLabelTableViewCell
            cell.handshakeLabel.text = NSLocalizedString("Partner:", comment: "Partner label, handshake")
            return cell
        } else if ((indexPath as NSIndexPath).row == partnerContact) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "contactCell", for: indexPath) as! HandshakeLabelTableViewCell
            cell.handshakeLabel.text = partner!.displayString()
            return cell
        } else if ((indexPath as NSIndexPath).row == explanationTrustwords) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "trustwordCell", for: indexPath) as! HandshakeTexViewTableViewCell
            cell.handshakeTextView.text = NSLocalizedString("Ask your partner: What are your trustword? then compare to the correct answer shown below.", comment: "Handshake explanation")
            return cell
        } else if ((indexPath as NSIndexPath).row == trustwords) {

            let cell = tableView.dequeueReusableCell(withIdentifier: "trustwordCell", for: indexPath) as! HandshakeTexViewTableViewCell
            if let p = partner, let myselfEmail = appConfig.currentAccount?.user.address,
                let myselfContact = appConfig.model.contactByEmail(myselfEmail) {
                let partnerPepContact = PEPUtil.pepContact(p)
                let myselfContactPepContact = PEPUtil.pepContact(myselfContact)
                let recognizer = UITapGestureRecognizer(target: self, action:#selector(HandshakeViewController.handleTap(_:)))
                recognizer.delegate = self
                cell.handshakeTextView.addGestureRecognizer(recognizer)
                if !hexamode {
                    cell.handshakeTextView.text = PEPUtil.trustwordsForIdentity1(
                        myselfContactPepContact, identity2: partnerPepContact,
                        language: "en", session: nil)
                } else {
                    let myselfFingerprints = PEPUtil.fingprprintForContact(myselfContact)

                    let partnerFingerprints = PEPUtil.fingprprintForContact(partner!)
                    let bothFingerprints = "\(fingerprintFormat(partnerFingerprints!))\n\n\(fingerprintFormat(myselfFingerprints!))"
                    cell.handshakeTextView.text = bothFingerprints
                    cell.handshakeTextView.font = UIFont(name: "Menlo", size: UIFont.systemFontSize)
                }
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "handshakeButton", for: indexPath) as! HandshakeButtonTableViewCell
            cell.confirmUIButton.setTitle(NSLocalizedString("Confirm trustwords", comment: "confirm button, handshake"), for: UIControlState())
            cell.confirmUIButton.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
            cell.confirmUIButton.imageEdgeInsets = UIEdgeInsetsMake(0, -20, 0, 0)
            cell.deniedUIButton.setTitle(NSLocalizedString("Wrong trustwords", comment: "wrong trustwords button, handshake"), for: UIControlState())
            cell.deniedUIButton.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
            cell.deniedUIButton.imageEdgeInsets = UIEdgeInsetsMake(0, -20, 0, 0)
            return cell
        }
    }

    func fingerprintFormat(_ fingerprint: String) -> String {
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

    @IBAction func confirmTrustwords(_ sender: AnyObject) {
        if let p = partner {
            PEPUtil.trustContact(p)
            let _ = navigationController?.popViewController(animated: true)
        }
    }

    @IBAction func wrongTrustwords(_ sender: AnyObject) {
        if let p = partner {
            PEPUtil.mistrustContact(p)
            let _ = navigationController?.popViewController(animated: true)
        }
    }

    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        hexamode = !hexamode
        self.tableView.reloadData()
    }
}

