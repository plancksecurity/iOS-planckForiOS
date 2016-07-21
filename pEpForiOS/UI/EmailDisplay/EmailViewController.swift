//
//  EmailViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 31/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class EmailViewController: UIViewController {
    let segueReply = "segueReply"
    let segueTrustWordsContactList = "segueTrustWordsContactList"


    let headerGapToContentY: CGFloat = 25

    struct UIState {
        var loadingMail = false
    }

    let state = UIState()
    var appConfig: AppConfig!
    let headerView = EmailHeaderView.init()
    var webView: WKWebView!

    var message: Message!

    override func viewDidLoad() {
        super.viewDidLoad()
        let config = WKWebViewConfiguration.init()
        webView = WKWebView.init(frame: view.frame, configuration: config)
        view.addSubview(webView)
        webView.scrollView.addSubview(headerView)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateContents()
    }

    func updateContents() {
        // If the contentInset.top is already set, this means the view never
        // really disappeared. So there is nothing to update in that case.
        if webView.scrollView.contentInset.top == 0 {
            headerView.message = message
            headerView.update(view.bounds.size.width)

            loadWebViewContent()

            let headerViewSize = headerView.preferredSize

            let calculatedInsetTop = headerViewSize.height + headerGapToContentY
            webView.scrollView.contentInset.top += calculatedInsetTop

            headerView.frame = CGRect.init(origin: CGPoint.init(x: 0, y: -calculatedInsetTop),
                                           size: headerViewSize)
            webView.frame = CGRect.init(origin: CGPoint.init(x: 0, y: 0),
                                        size: CGSize.init(width: view.bounds.size.width,
                                            height: view.bounds.size.height))
        }
    }

    func loadWebViewContent() {
        if let url = NSURL.init(string: "file:///") {
            if let s = message.longMessageFormatted {
                webView.loadHTMLString(s, baseURL: url)
            } else if let s = message.longMessage {
                webView.loadHTMLString(s, baseURL: url)
            }
        }
    }

    @IBAction func pressReply(sender: UIBarButtonItem) {
        let alertViewWithoutTittle = UIAlertController()
        let alertActionReply = UIAlertAction (title: NSLocalizedString("Reply",
            comment: "Reply button text for reply action in AlertView in the screen with the message details"),
                                              style: .Default) { (action) in
                self.performSegueWithIdentifier(self.segueReply , sender: self)
        }
        alertViewWithoutTittle.addAction(alertActionReply)

        let alertActionReplyAll = UIAlertAction(
            title: NSLocalizedString("Reply All",
                comment: "Reply all button text for reply all action in AlertView in the screen with the message details"),
            style: .Default) { (action) in }
        alertViewWithoutTittle.addAction(alertActionReplyAll)

        let alertActionForward = UIAlertAction(
            title: NSLocalizedString("Forward",
                comment: "Forward button text for forward action in AlertView in the screen with the message details"),
            style: .Default) { (action) in }
        alertViewWithoutTittle.addAction(alertActionForward)

        let cancelAction = UIAlertAction(
            title: NSLocalizedString("Cancel",
                comment: "Cancel button text for cancel action in AlertView in the screen with the message details"),
            style: .Cancel) { (action) in }

        alertViewWithoutTittle.addAction(cancelAction)

        presentViewController(alertViewWithoutTittle, animated: true, completion: nil)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == segueReply) {
            let destination = segue.destinationViewController
                as? ComposeViewController;
            destination?.appConfig = appConfig
        }
        if (segue.identifier == segueTrustWordsContactList) {
            let destination = segue.destinationViewController as? TrustWordsViewController
            destination?.message = self.message
        }
    }
}