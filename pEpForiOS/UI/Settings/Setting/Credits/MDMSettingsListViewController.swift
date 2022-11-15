//
//  MDMSettingsListViewController.swift
//  pEp
//
//  Created by Martín Brude on 6/10/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

class MDMSettingsListViewController: PEPWebViewController {

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            webView.backgroundColor = UIColor.systemBackground
        } else {
            webView.backgroundColor = .white
        }
        title = NSLocalizedString("Current MDM Settings", comment: "Current MDM Settings view title")
        webView.loadHTMLString(html(), baseURL: nil)
        setupShareButton()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(pEpMDMSettingsChanged),
                                               name: .pEpMDMSettingsChanged,
                                               object: nil)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let thePreviousTraitCollection = previousTraitCollection else {
            // Valid case: optional value from Apple.
            return
        }
        if #available(iOS 13.0, *) {
            if thePreviousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) {
                // As the html needs to change, we don't reload the existing html.
                // Instead we re-define it and then the load the new one.
                webView.loadHTMLString(html(), baseURL: nil)
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Private

extension MDMSettingsListViewController {

    private func setupShareButton() {
        let buttonTitle = NSLocalizedString("Share", comment: "Share button title")
        let shareButton = UIBarButtonItem(title: buttonTitle,
                                          style: .done,
                                          target: self,
                                          action: #selector(shareButtonPressed))
        shareButton.accessibilityIdentifier = AccessibilityIdentifier.shareButton
        shareButton.isAccessibilityElement = true
        navigationItem.rightBarButtonItem = shareButton
    }

    /// Share the settings list.
    @objc private func shareButtonPressed(sender: UIBarButtonItem) {
        let vc = getActivityViewController(sender: sender)
        present(vc, animated: true, completion: nil)
    }

    private func getActivityViewController(sender: UIBarButtonItem) -> UIActivityViewController {
        let dictionary : String = MDMPredeployed().mdmPrettyPrintedDictionary()
        let activityViewController = UIActivityViewController(activityItems: [dictionary], applicationActivities: nil)
        activityViewController.title = NSLocalizedString("Share MDM settings", comment: "Share MDM settings title")

        //Ipad config
        let sourceView = sender.value(forKey: "view") as? UIView
        activityViewController.popoverPresentationController?.sourceView = sourceView ?? view
        activityViewController.popoverPresentationController?.permittedArrowDirections = .up

        // Pre-configuring activity items
        if #available(iOS 13.0, *) {
            activityViewController.activityItemsConfiguration = [
                UIActivity.ActivityType.message
            ] as? UIActivityItemsConfigurationReading
        } else {
            // Fallback on earlier versions
        }

        activityViewController.excludedActivityTypes = [
            UIActivity.ActivityType.postToWeibo,
            UIActivity.ActivityType.print,
            UIActivity.ActivityType.assignToContact,
            UIActivity.ActivityType.saveToCameraRoll,
            UIActivity.ActivityType.addToReadingList,
            UIActivity.ActivityType.postToFlickr,
            UIActivity.ActivityType.postToVimeo,
            UIActivity.ActivityType.postToTencentWeibo,
            UIActivity.ActivityType.postToFacebook,
            UIActivity.ActivityType.postToTwitter
        ]

        if #available(iOS 13.0, *) {
            activityViewController.isModalInPresentation = true
        } else {
            // Fallback on earlier versions
        }
        return activityViewController
    }

    private func html() -> String {
        let json = MDMPredeployed().mdmPrettyPrintedDictionary()
        var backgroundColor = UIColor.white
        var fontColor = UIColor.pEpGray

        if #available(iOS 13.0, *) {
            backgroundColor = UIColor.systemBackground
            fontColor = UIColor.label
        }
        let fontSize = "18"
        let fontFamily = "Helvetica Neue"
        let fontWeight = "500"
        let styleP = "p {color: \(fontColor.toHex());font-size: \(fontSize)px;font-family: \(fontFamily);font-weight: \(fontWeight);}"
        let styleBody = "body {background-color: \(backgroundColor.toHex()); margin-left: 0px; margin-right: 0px;}"
        let styleA = "a {color: \(fontColor.toHex());font-size: \(fontSize)px;font-family: \(fontFamily);font-weight: \(fontWeight);}"
        let styleLink = "a:link {color:\(UIColor.pEpDarkGreenHex); text-decoration: underline; word-break: break-all; !important;}"
        let style = "<style>\(styleP)\(styleBody)\(styleA)\(styleLink)</style>"
        let result = """
        <html>
         <head>
           \(style)
           <meta name="viewport" content="width=device-width, initial-scale=1.0">
           <meta charset="utf-8"/>
        </head>
        <body>
        <blockquote>
        <p>\(json)</p>
        </blockquote>
        </body>
        </html>
        """
        return result
    }

    @objc private func pEpMDMSettingsChanged() {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.webView.loadHTMLString(me.html(), baseURL: nil)
        }
    }

}
