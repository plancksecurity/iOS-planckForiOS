//
//  FullMessageCell.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 14/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel

class FullMessageCell: UITableViewCell,
    MessageViewModelConfigurable,
    NeedsRefreshDelegate {
    
    var requestsReload: (() -> Void)?

    @IBOutlet weak var contentHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var roundedView: UIView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var bodyText: UITextView!
    @IBOutlet weak var body: UIView!
    @IBOutlet weak var stackView: UIStackView!

    var tableView: UITableView!

    @IBOutlet weak var view: UIView!
    func configure(for viewModel:MessageViewModel) {
        addressLabel.text = viewModel.from
        subjectLabel.text = viewModel.subject
        backgroundColor = UIColor.clear
        dateLabel.text = viewModel.dateText
        if let htmlBody = htmlBody(message: viewModel.message) {
            // Its fine to use a webview (iOS>=11) and we do have HTML content.
            bodyText.isHidden = true
            view.addSubview(htmlViewerViewController.view)
            view.isUserInteractionEnabled = false

            htmlViewerViewController.view.fullSizeInSuperView()

            let displayHtml = appendInlinedPlainText(fromAttachmentsIn: viewModel.message, to: htmlBody)
            htmlViewerViewController.display(htmlString: displayHtml)
        } else {
            bodyText.attributedText = viewModel.body
            bodyText.isHidden = false
            bodyText.tintColor = UIColor.pEpGreen
            // We are not allowed to use a webview (iOS<11) or do not have HTML content.
            // Remove the HTML view if we just stepped from an HTML mail to one without
            if htmlViewerViewControllerExists &&
                htmlViewerViewController.view.superview == self.contentView {
                htmlViewerViewController.view.removeFromSuperview()
            }
        }

    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
    }

    /**
     Indicate that the htmlViewerViewController already exists, to avoid
     instantiation just to check if it has been instantiated.
     */
    var htmlViewerViewControllerExists = false

    lazy private var htmlViewerViewController: SecureWebViewController = {
        let storyboard = UIStoryboard(name: "Reusable", bundle: nil)
        guard let vc =
            storyboard.instantiateViewController(withIdentifier: SecureWebViewController.storyboardId)
                as? SecureWebViewController
            else {
                Log.shared.errorAndCrash(component: #function, errorString: "Cast error")
                return SecureWebViewController()
        }
        vc.scrollingEnabled = false
        vc.delegate = self

        htmlViewerViewControllerExists = true

        return vc
    }()

    /**
     Yields the HTML message body if:
     * we can show it in a secure way
     * we have non-empty HTML content at all
     - Returns: The HTML message body or nil
     */
    private func htmlBody(message: Message?) ->  String? {
        guard
            SecureWebViewController.isSaveToUseWebView,
            let m = message,
            let htmlBody = m.longMessageFormatted,
            !htmlBody.isEmpty else {
                return nil
        }

        return htmlBody
    }

    private func appendInlinedPlainText(fromAttachmentsIn message: Message, to text: String) -> String {
        var result = text
        let inlinedText = message.inlinedTextAttachments()
        for inlinedTextAttachment in inlinedText {
            guard
                let data = inlinedTextAttachment.data,
                let inlinedText = String(data: data, encoding: .utf8) else {
                    continue
            }
            result = append(appendText: inlinedText, to: result)
        }
        return result
    }

    private func append(appendText: String, to body: String) -> String {
        var result = body
        let replacee = result.contains(find: "</body>") ? "</body>" : "</html>"
        if result.contains(find: replacee) {
            result = result.replacingOccurrences(of: replacee, with: appendText + replacee)
        } else {
            result += "\n" + appendText
        }
        return result
    }


}
