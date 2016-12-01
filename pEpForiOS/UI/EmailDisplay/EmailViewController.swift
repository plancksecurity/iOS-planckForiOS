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

import MessageModel

class EmailViewController: UIViewController {
    /** Segue name for replying to the sender (from) */
    let segueReplyFrom = "segueReplyFrom"

    /** Segue name for forwarding email */
    let segueForward = "segueForward"

    /** Segue for invoking the trustwords controller */
    let segueTrustWordsContactList = "segueTrustWordsContactList"

    let headerGapToContentY: CGFloat = 25

    struct UIState {
        var loadingMail = false
    }

    var state = UIState()
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateContents()
    }

    func updateContents() {
        // If the contentInset.top is already set, this means the view never
        // really disappeared. So there is nothing to update in that case.
        headerView.message = message
        headerView.update(view.bounds.size.width)

        // Mark as read. Duh!
        message.imapFlags?.seen = true

        if webView.scrollView.contentInset.top == 0 {
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
        let font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
        let fontSize = font.pointSize
        let fontFamily = font.familyName

        if let url = URL.init(string: "file:///") {
            if let s = message.longMessage {
                let s2 = s.replacingOccurrences(of: "\r\n", with: "<br>")
                let s3 = s2.replacingOccurrences(of: "\n", with: "<br>")
                let html: String = "<!DOCTYPE html>"
                    + "<html>"
                    + "<head>"
                    + "<meta name=\"viewport\" content=\"initial-scale=1.0\" />"
                    + "<style>"
                    + "body {font-size: \(fontSize); font-family: '\(fontFamily)'}"
                    + "</style>"
                    + "</head>"
                    + "<body>"
                    + s3
                    + "</body>"
                    + "</html>"

                webView.loadHTMLString(html, baseURL: url)
            }
        }
    }

    @IBAction func pressReply(_ sender: UIBarButtonItem) {
        let alertViewWithoutTitle = UIAlertController()

        let alertActionReply = UIAlertAction (
            title: NSLocalizedString("Reply",
                comment: "Reply email button"), style: .default) { (action) in
                    self.performSegue(withIdentifier: self.segueReplyFrom , sender: self)
        }
        alertViewWithoutTitle.addAction(alertActionReply)

        let alertActionForward = UIAlertAction (
            title: NSLocalizedString("Forward",
                comment: "Forward email button"), style: .default) { (action) in
                    self.performSegue(withIdentifier: self.segueForward , sender: self)
        }
        alertViewWithoutTitle.addAction(alertActionForward)

        let cancelAction = UIAlertAction(
            title: NSLocalizedString("Cancel",
                comment: "Cancel button text for email actions menu (reply, forward etc.)"),
            style: .cancel) { (action) in }

        alertViewWithoutTitle.addAction(cancelAction)

        present(alertViewWithoutTitle, animated: true, completion: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == segueReplyFrom) {
            let destination = segue.destination
                as? ComposeViewController;
            destination?.composeMode = .replyFrom
            destination?.appConfig = appConfig
            destination?.originalMessage = message
        } else if (segue.identifier == segueForward) {
            let destination = segue.destination
                as? ComposeViewController;
            destination?.composeMode = .forward
            destination?.appConfig = appConfig
            destination?.originalMessage = message
        } else if (segue.identifier == segueTrustWordsContactList) {
            let destination = segue.destination as? TrustWordsViewController
            destination?.message = self.message
            destination?.appConfig = appConfig
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        print("Transition size: \(size)")
        updateViews(with: size)
    }
    
    func updateViews(with size: CGSize) {
        webView.frame.size = size
    }
}
