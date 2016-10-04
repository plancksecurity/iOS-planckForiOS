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
    var appConfig: AppConfig?

    @IBOutlet weak var sender: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
            if appConfig == nil {
                if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                    appConfig = appDelegate.appConfig
                }
            }
            let account: CdAccount? = appConfig!.model.fetchLastAccount()
            if (account == nil)  {
                self.performSegue(withIdentifier: "userSettings", sender: self)
            }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return allMailList.listOfMails.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:MailCell = tableView.dequeueReusableCell(withIdentifier: "mailCell", for: indexPath) as! MailCell
        cell.senderName?.text = allMailList.listOfMails[(indexPath as NSIndexPath).row].senderName
        cell.subject.text = allMailList.listOfMails[(indexPath as NSIndexPath).row].subject
        cell.contentMail?.text = allMailList.listOfMails[(indexPath as NSIndexPath).row].contentMail
        cell.hour?.text = allMailList.listOfMails[(indexPath as NSIndexPath).row].hour

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "userSettings" {
            if let destination = segue.destination as? UserInfoTableView {
                destination.appConfig = appConfig
            }
        }
    }

}

