//
//  EmailViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 31/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

import MessageModel

class EmailViewController: BaseTableViewController {
    @IBOutlet weak var handShakeButton: UIBarButtonItem!
    @IBOutlet weak var flagButton: UIBarButtonItem!
    @IBOutlet weak var destructiveButton: UIBarButtonItem!
    @IBOutlet weak var previousMessage: UIBarButtonItem!
    @IBOutlet weak var nextMessage: UIBarButtonItem!

    var message: Message?
    var folderShow : Folder?
    var messageId = 0

    private var partnerIdentity: Identity?
    private var tableData: ComposeDataSource?
    private var ratingReEvaluator: RatingReEvaluator?
    lazy private var backgroundQueue = OperationQueue()
    lazy private var documentInteractionController = UIDocumentInteractionController()

    // MARK: - LIFE CYCLE

    override func viewDidLoad() {
        super.viewDidLoad()

        loadDatasource("MessageData")

        tableView.estimatedRowHeight = 72.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureView()
    }

    // MARK: - UTIL

    private func updateFlaggedStatus() {
        if message?.imapFlags?.flagged ?? false {
            flagButton.image = UIImage.init(named: "icon-flagged")
        } else {
            flagButton.image = UIImage.init(named: "icon-unflagged")
        }
    }

    private func checkMessageReEvaluation() {
        if let m = message, ratingReEvaluator?.message != m {
            ratingReEvaluator = RatingReEvaluator(parentName: #function, message: m)
            ratingReEvaluator?.delegate = self
        }
    }

    private func showPepRating() {
        let session = PEPSession()
        let _ = showPepRating(pEpRating: message?.pEpRating(session: session))
        let handshakeCombos = message?.handshakeActionCombinations(session: session) ?? []
        handShakeButton.isEnabled = !handshakeCombos.isEmpty
    }


    private final func loadDatasource(_ file: String) {
        if let path = Bundle.main.path(forResource: file, ofType: "plist") {
            if let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
                tableData = ComposeDataSource(with: dict["Rows"] as! [[String: Any]])
            }
        }
    }

    // MARK: - SETUP

    private func configureView() {
        // Make sure the NavigationBar is shown, even if the previous view has hidden it.
        navigationController?.setNavigationBarHidden(false, animated: false)

        self.title = NSLocalizedString("Message", comment: "Message view title")

        setupDestructiveButtonIcon()

        tableData?.filterRows(message: message)

        if messageId <= 0 {
            self.previousMessage.isEnabled = false
        } else {
            self.previousMessage.isEnabled = true
        }

        self.showPepRating()

        DispatchQueue.main.async {
            self.checkMessageReEvaluation()

            self.message?.markAsSeen()

            if let total = self.folderShow?.messageCount(), self.messageId >= total - 1 {
                self.nextMessage.isEnabled = false
            } else {
                self.nextMessage.isEnabled = true
            }
        }
        updateFlaggedStatus()
    }

    // Sets the destructive bottom bar item accordint to the message (trash/archive)
    private func setupDestructiveButtonIcon() {
        guard let msg = message else {
            Log.shared.errorAndCrash(component: #function, errorString: "No message")
            return
        }

        //IOS-938:
        // We currently are lacking an archive icon asset and thus show the trash bin for archiving also.
        // After getting the icon set it using the below commented if clause.
//        if msg.parent.defaultDestructiveActionIsArchive {
//            destructiveButton = UIBarButtonItem(image: UIImage(named:NAME_OF_ARCHIVE_ICON_GOES_HERE), style: .plain, target: self, action: #selector(deleteButtonTapped(_:)))
//        } else {
//             destructiveButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteButtonTapped(_:))
//        }

    }

    // MARK: - EMAIL BODY

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

    private func setup(contentCell: MessageContentCell, rowData: ComposeFieldModel) {
        guard let m = message else {
            Log.shared.errorAndCrash(component: #function, errorString: "No msg.")
            return
        }
        if let htmlBody = htmlBody(message: m) {
            // Its fine to use a webview (iOS>=11) and we do have HTML content.
            contentCell.contentView.addSubview(htmlViewerViewController.view)
            htmlViewerViewController.view.fullSizeInSuperView()
            let displayHtml = appendInlinedPlainText(fromAttachmentsIn: m, to: htmlBody)
            htmlViewerViewController.display(htmlString: displayHtml)
        } else {
            // We are not allowed to use a webview (iOS<11) or do not have HTML content.
            // Remove the HTML view if we just stepped from an HTML mail to one without
            if htmlViewerViewControllerExists &&
                htmlViewerViewController.view.superview == contentCell.contentView {
                htmlViewerViewController.view.removeFromSuperview()
            }
            contentCell.updateCell(model: rowData, message: m)
        }
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

    // MARK: - IBActions

    @IBAction func next(_ sender: Any) {
        messageId += 1
        if let m = folderShow?.messageAt(index: messageId) {
            message = m
        }
        self.tableView.reloadData()
        configureView()
    }

    @IBAction func previous(_ sender: Any) {
        messageId -= 1
        if let m = folderShow?.messageAt(index: messageId) {
            message = m
        }
        self.tableView.reloadData()
        configureView()
    }

    @IBAction func pressReply(_ sender: UIBarButtonItem) {
        let alertViewWithoutTitle = UIAlertController()
        alertViewWithoutTitle.view.tintColor = .pEpGreen

        if let popoverPresentationController = alertViewWithoutTitle.popoverPresentationController {
            popoverPresentationController.barButtonItem = sender
        }

        let alertActionReply = UIAlertAction(
            title: NSLocalizedString("Reply", comment: "Message actions"),
            style: .default) { (action) in
                self.performSegue(withIdentifier: .segueReplyFrom , sender: self)
        }
        alertViewWithoutTitle.addAction(alertActionReply)

        let alertActionReplyAll = UIAlertAction(
            title: NSLocalizedString("Reply All", comment: "Message actions"),
            style: .default) { (action) in
                self.performSegue(withIdentifier: .segueReplyAllForm , sender: self)
        }
        alertViewWithoutTitle.addAction(alertActionReplyAll)

        let alertActionForward = UIAlertAction(
            title: NSLocalizedString("Forward", comment: "Message actions"),
            style: .default) { (action) in
                self.performSegue(withIdentifier: .segueForward , sender: self)
        }
        alertViewWithoutTitle.addAction(alertActionForward)

        let cancelAction = UIAlertAction(
            title: NSLocalizedString("Cancel", comment: "Message actions"),
            style: .cancel) { (action) in }
        alertViewWithoutTitle.addAction(cancelAction)

        present(alertViewWithoutTitle, animated: true, completion: nil)
    }

    @IBAction func flagButtonTapped(_ sender: UIBarButtonItem) {
        if (message?.imapFlags?.flagged == true) {
            message?.imapFlags?.flagged = false
        } else {
            message?.imapFlags?.flagged = true
        }
        message?.save()

        updateFlaggedStatus()
    }


    @IBAction func moveToFolderButtonTapped(_ sender: UIBarButtonItem) {
        //TODO:
    }


    @IBAction func deleteButtonTapped(_ sender: UIBarButtonItem) {
        message?.imapDelete() // mark for deletion/trash
        _ = navigationController?.popViewController(animated: true)
    }

    /**
     For the unwind segue from the trustwords controller, when the user choses "trusted".
     */
    @IBAction func segueUnwindTrusted(segue: UIStoryboardSegue) {
        if let p = partnerIdentity {
            let session = PEPSession()
            do {
                try PEPUtil.trust(identity: p, session: session)
            } catch let error as NSError {
                assertionFailure("\(error)")
            }
            decryptAgain()
        }
    }

    /**
     For the unwind segue from the trustwords controller, when the user choses "untrusted".
     */
    @IBAction func segueUnwindUnTrusted(segue: UIStoryboardSegue) {
        if let p = partnerIdentity {
            let session = PEPSession()
            do {
                try PEPUtil.mistrust(identity: p, session: session)
            } catch let error as NSError {
                assertionFailure("\(error)")
            }
            decryptAgain()
        }
    }

    private func decryptAgain() {
        ratingReEvaluator?.reevaluateRating()
    }
}

// MARK: - UITableViewDataSource

extension EmailViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData?.numberOfRows() ?? 0
    }

    override func tableView(
        _ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let row = tableData?.getRow(at: indexPath.row),
            let cell = tableView.dequeueReusableCell(
                withIdentifier: row.identifier,
                for: indexPath) as? MessageCell,
            let m = message else {
                    return UITableViewCell()
        }
        if let contentCell = cell as? MessageContentCell {
            setup(contentCell: contentCell, rowData: row)
        } else {
            cell.updateCell(model: row, message: m)
        }
        cell.delegate = self
        return cell
    }

    override func tableView(
        _ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard
            let row = tableData?.getRow(at: indexPath.row) else {
                Log.shared.errorAndCrash(component: #function, errorString: "Missing data")
                return tableView.estimatedRowHeight
        }

        if row.type == .content, htmlBody(message: message) != nil {
            return htmlViewerViewController.contentSize?.height ?? tableView.rowHeight
        } else {
            return tableView.rowHeight
        }
    }
}

// MARK: - MessageContentCellDelegate

extension EmailViewController: MessageContentCellDelegate {
    func didUpdate(cell: MessageCell, height: CGFloat) {
        tableView.updateSize()
    }
}

// MARK: - SegueHandlerType

extension EmailViewController: SegueHandlerType {
    enum SegueIdentifier: String {
        case segueReplyFrom
        case segueReplyAllForm
        case segueForward
        case segueHandshake
        case segueCompose
        case noSegue
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let theId = segueIdentifier(for: segue)
        switch theId {
        case .segueReplyFrom, .segueReplyAllForm, .segueForward, .segueCompose:
            guard  let nav = segue.destination as? UINavigationController,
                let destination = nav.topViewController as? ComposeTableViewController else {
                    Log.shared.errorAndCrash(component: #function, errorString: "No DVC?")
                    break
            }

            destination.appConfig = appConfig

            if theId == .segueReplyFrom {
                destination.composeMode = .replyFrom
                destination.originalMessage = message
            } else if theId == .segueReplyAllForm {
                destination.composeMode = .replyAll
                destination.originalMessage = message
            } else if theId == .segueForward {
                destination.composeMode = .forward
                destination.originalMessage = message
            } else if theId == .segueCompose {
            }
        case .segueHandshake:
            guard let destination = segue.destination as? HandshakeViewController else {
                Log.shared.errorAndCrash(component: #function, errorString: "No DVC?")
                break
            }
            destination.appConfig = appConfig
            destination.message = message
            destination.ratingReEvaluator = ratingReEvaluator
            break
        case .noSegue:
            break
        }
    }
}

// MARK: - RatingReEvaluatorDelegate

extension EmailViewController: RatingReEvaluatorDelegate {
    func ratingChanged(message: Message) {
        GCD.onMain { [weak self] in
            self?.showPepRating()
        }
    }
}

// MARK: - MessageAttachmentDelegate

extension EmailViewController: MessageAttachmentDelegate {
    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        if UI_USER_INTERFACE_IDIOM() == .pad {
            documentInteractionController.dismissMenu(animated: false)
        }
    }

    func didCreateLocally(attachment: Attachment, url: URL, cell: MessageCell, location: CGPoint,
                          inView: UIView?) {
        documentInteractionController.url = url
        let theView = inView ?? cell
        let dim: CGFloat = 40
        let rect = CGRect.rectAround(center: location, width: dim, height: dim)
        documentInteractionController.presentOptionsMenu(from: rect, in: theView, animated: true)
    }

    func didTap(cell: MessageCell, attachment: Attachment, location: CGPoint, inView: UIView?) {
        let busyState = inView?.displayAsBusy()
        let attachmentOp = AttachmentToLocalURLOperation(attachment: attachment)
        attachmentOp.completionBlock = { [weak self] in
            attachmentOp.completionBlock = nil
            GCD.onMain {
                defer {
                    if let bState = busyState {
                        inView?.stopDisplayingAsBusy(viewBusyState: bState)
                    }
                }
                guard let url = attachmentOp.fileURL else {
                    return
                }
                self?.didCreateLocally(attachment: attachment, url: url, cell: cell,
                                       location: location, inView: inView)
            }
        }
        backgroundQueue.addOperation(attachmentOp)
    }
}

// MARK: - SecureWebViewControllerDelegate

extension EmailViewController: SecureWebViewControllerDelegate {
    func secureWebViewController(_ webViewController: SecureWebViewController,
                                 sizeChangedTo size: CGSize) {
        tableView.updateSize()
    }
}
