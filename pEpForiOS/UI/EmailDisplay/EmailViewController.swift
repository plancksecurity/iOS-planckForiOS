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

class EmailViewController: UITableViewController {
    
    @IBOutlet weak var forwardButton: UIBarButtonItem!
    @IBOutlet weak var backButton: UIBarButtonItem!

    var message: Message!
    var appConfig: AppConfig!
    var page = 0
    
    
    let headerGapToContentY: CGFloat = 25
    let headerView = EmailHeaderView()
    var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: view.frame, configuration: config)
        view.addSubview(webView)
        webView.scrollView.addSubview(headerView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateContents()
    }

    func updateContents() {
        
        // Mark as read. Duh!
        message.imapFlags?.seen = true
        
        // If the contentInset.top is already set, this means the view never
        // really disappeared. So there is nothing to update in that case.
        headerView.message = message
        headerView.update(view.bounds.size.width)

        if webView.scrollView.contentInset.top == 0 {
            loadWebViewContent()

            let headerViewSize = headerView.preferredSize

            let calculatedInsetTop = headerViewSize.height + headerGapToContentY
            webView.scrollView.contentInset.top += calculatedInsetTop

            headerView.frame = CGRect(origin: CGPoint(x: 0, y: -calculatedInsetTop), size: headerViewSize)
            webView.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: view.bounds.size.width, height: view.bounds.size.height))
        }
    }

    func loadWebViewContent() {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let fontSize = font.pointSize
        let fontFamily = font.familyName

        if let url = URL(string: "file:///") {
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
            title: "Reply".localized, style: .default) { (action) in
                self.performSegue(withIdentifier: .segueReplyFrom, sender: self)
        }
        alertViewWithoutTitle.addAction(alertActionReply)

        let alertActionForward = UIAlertAction (
            title: "Forward".localized, style: .default) { (action) in
                self.performSegue(withIdentifier: .segueForward, sender: self)
        }
        alertViewWithoutTitle.addAction(alertActionForward)

        let cancelAction = UIAlertAction(
            title: "Cancel".localized, style: .cancel) { (action) in }

        alertViewWithoutTitle.addAction(cancelAction)
        
        present(alertViewWithoutTitle, animated: true, completion: nil)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        print("Transition size: \(size)")
        updateViews(with: size)
    }
    
    func updateViews(with size: CGSize) {
        webView.frame.size = size
    }
}


// MARK: - SegueHandlerType

extension EmailViewController: SegueHandlerType {
    
    enum SegueIdentifier: String {
        case segueReplyFrom
        case segueForward
        case segueTrustWords
        case seguePrevious
        case segueNext
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .segueReplyFrom:
            let destination = segue.destination as? ComposeTableViewController
            destination?.composeMode = .from
            destination?.appConfig = appConfig
            destination?.originalMessage = message
            break
        case .segueForward:
            let destination = segue.destination as? ComposeTableViewController
            destination?.composeMode = .forward
            destination?.appConfig = appConfig
            destination?.originalMessage = message
            break
        case .segueTrustWords:
            let destination = segue.destination as? TrustWordsViewController
            destination?.message = message
            destination?.appConfig = appConfig
            break
        case .seguePrevious:
            page = page > 0 ? page - 1 : 0
            let destination = segue.destination as! EmailViewController
            destination.appConfig = appConfig
            destination.page = page
            break
        case .segueNext:
            page += 1
            let destination = segue.destination as! EmailViewController
            destination.appConfig = appConfig
            destination.page = page
            break
        }
    }
}
