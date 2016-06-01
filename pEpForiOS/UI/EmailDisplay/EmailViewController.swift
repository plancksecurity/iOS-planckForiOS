//
//  EmailViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 31/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

class EmailViewController: UITableViewController {
    struct UIState {
        var loadingMail: Bool = false
    }

    @IBOutlet weak var toStackView: UIStackView!
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var contentWebView: UIWebView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    let state = UIState()
    var appConfig: AppConfig!
    var message: Message!

    override func viewDidLoad() {
        super.viewDidLoad()
        UIHelper.variableCellHeightsTableView(self.tableView)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        fromLabel.text = message.from?.displayString()
        addToRecipients()

        if message.fetched.boolValue {
            extractMessageContent()
        } else {
            let folder = message.folder
            let account = folder.account
            if let suid = message.uid?.integerValue {
                let uid = UInt(bitPattern: suid)
                appConfig.grandOperator.fetchMailFromFolderNamed(
                    account.connectInfo, folderName: folder.name, uid: uid,
                    completionBlock: { error in
                })
            }
        }
    }

    func addToRecipients() {
        for v in toStackView.subviews {
            v.removeFromSuperview()
        }
        for r in message.to {
            if let c = r as? Contact {
                let l = UIHelper.labelFromContact(c)
                toStackView.addArrangedSubview(l)
            }
        }
    }

    func extractMessageContent() {
        if let text = message.longMessage {
            print("text \(text)")
        } else if let html = message.longMessageFormatted {
            print("html \(html)")
        }
    }
}
