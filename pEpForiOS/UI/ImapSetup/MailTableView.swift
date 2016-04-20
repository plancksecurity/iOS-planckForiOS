//
//  MyTableViewMail.swift
//  pEpDemo
//
//  Created by ana on 12/4/16.
//  Copyright © 2016 pEp. All rights reserved.
//

import UIKit

class MailTableView: UITableViewController {

     var mailParameters = MailSettingParameters()

    let allMailList = MailList()

    @IBOutlet weak var sender: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        print (mailParameters.email)
        print (mailParameters.username)
        print (mailParameters.password)

        print (mailParameters.serverhostIMAP)
        print (mailParameters.portIMAP)
        //print (mailParameters.transportSecurityIMAP)

        print (mailParameters.serverhostSMTP)
        print (mailParameters.portSMTP)
        //print (mailParameters.transportSecuritySMTP)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return allMailList.listOfMails.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:MailCell = tableView.dequeueReusableCellWithIdentifier("mailCell", forIndexPath: indexPath) as! MailCell
        cell.senderName?.text = allMailList.listOfMails[indexPath.row].senderName
        cell.subject.text = allMailList.listOfMails[indexPath.row].subject
        cell.contentMail?.text = allMailList.listOfMails[indexPath.row].contentMail
        cell.hour?.text = allMailList.listOfMails[indexPath.row].hour

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
}

