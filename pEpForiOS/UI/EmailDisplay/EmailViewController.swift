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
    @IBOutlet var flagButton: UIBarButtonItem!
    @IBOutlet var destructiveButton: UIBarButtonItem!
    @IBOutlet var previousMessage: UIBarButtonItem!
    @IBOutlet var nextMessage: UIBarButtonItem!
    @IBOutlet var moveToFolderButton: UIBarButtonItem!
    @IBOutlet var replyButton: UIBarButtonItem!
    @IBOutlet var pepButton: UIBarButtonItem!
    @IBOutlet var pepRating: UIBarButtonItem!
    var barItems: [UIBarButtonItem]?

    var message: Message?
    var folderShow : Folder?
    var messageId = 0

    var shouldShowOKButton: Bool = false

    private var partnerIdentity: Identity?
    private var tableData: ComposeDataSource?
    private var ratingReEvaluator: RatingReEvaluator?
    lazy private var backgroundQueue = OperationQueue()
    lazy private var documentInteractionController = UIDocumentInteractionController()

    lazy var clickHandler: UrlClickHandler = {
        return UrlClickHandler(actor: self, appConfig: appConfig)
    }()

    weak var delegate: EmailDisplayDelegate?

    // MARK: - LIFE CYCLE

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSplitViewBackButton()
        configureOKButton()

        loadDatasource("MessageData")

        let item = UIBarButtonItem.getpEpButton(action: #selector(self.showSettingsViewController(_:)),
                                                target: self)
        let flexibleSpace: UIBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace,
            target: nil,
            action: nil)
        self.toolbarItems?.append(contentsOf: [flexibleSpace,item])

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
        changeFlagButtonTo(flagged: message?.imapFlags?.flagged ?? false)
    }

    internal func changeFlagButtonTo(flagged: Bool) {
        if (flagged) {
            flagButton.image = UIImage.init(named: "icon-flagged")
        }
        else {
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
        if let privacyStatusIcon = showPepRating(pEpRating: message?.pEpRating()) {
            let handshakeCombos = message?.handshakeActionCombinations() ?? []
            if !handshakeCombos.isEmpty {
                let tapGestureRecognizer = UITapGestureRecognizer(
                    target: self,
                    action: #selector(self.showHandshakeView(gestureRecognizer:)))
                privacyStatusIcon.addGestureRecognizer(tapGestureRecognizer)
            }
        }
    }


    private final func loadDatasource(_ file: String) {
        if let path = Bundle.main.path(forResource: file, ofType: "plist") {
            if let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
                tableData = ComposeDataSource(with: dict["Rows"] as! [[String: Any]])
            }
        }
    }

    // MARK: - SETUP

    internal func configureView() {
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

    private func configureSplitViewBackButton() {
        self.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        self.navigationItem.leftItemsSupplementBackButton = true
    }

    private func configureOKButton() {
        if (shouldShowOKButton) {
            let okButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: .okButtonPressed)
            self.navigationItem.leftBarButtonItems? = [okButton]
            self.navigationItem.hidesBackButton = true
        }
    }

    @objc internal func okButtonPressed(sender: UIBarButtonItem) {
        performSegue(withIdentifier: .unwindToThread, sender: self)
        print("what")
    }

    // Sets the destructive bottom bar item accordint to the message (trash/archive)
    private func setupDestructiveButtonIcon() {
        guard let msg = message else {
            Log.shared.errorAndCrash(component: #function, errorString: "No message")
            return
        }

        if msg.parent.defaultDestructiveActionIsArchive {
            // Replace the Storyboard set trash icon for providers that use "archive" rather than
            // "delete" as default
            destructiveButton.image = #imageLiteral(resourceName: "folders-icon-archive")
        }
    }

    // MARK: - UISplitViewcontrollerDelegate

    func splitViewController(willChangeTo displayMode: UISplitViewControllerDisplayMode) {
        switch displayMode {
        case .primaryHidden:
            var leftBarButtonItems: [UIBarButtonItem] = [nextMessage, previousMessage]
            if let unwrappedLeftBarButtonItems = navigationItem.leftBarButtonItems {
                leftBarButtonItems.append(contentsOf: unwrappedLeftBarButtonItems)
            }

            navigationItem.setLeftBarButtonItems(leftBarButtonItems.reversed(), animated: true)
            break
        case .allVisible:
            var leftBarButtonItems: [UIBarButtonItem] = []
            if let unwrappedLeftBarButtonItems = navigationItem.leftBarButtonItems?.first {
                leftBarButtonItems.append(unwrappedLeftBarButtonItems)
            }
            navigationItem.setLeftBarButtonItems(leftBarButtonItems, animated: true)
        default:
            //do nothing
            break
        }
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
        vc.urlClickHandler = clickHandler
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
            contentCell.updateCell(model: rowData, message: m, clickHandler: clickHandler)
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
        let alert = ReplyAlertCreator()
            .withReplyOption { action in
                self.performSegue(withIdentifier: .segueReplyFrom , sender: self)
            }.withReplyAllOption { action in
                self.performSegue(withIdentifier: .segueReplyAllForm , sender: self)
            }.withFordwardOption { action in
                self.performSegue(withIdentifier: .segueForward , sender: self)
            }.withCancelOption()
            .build()

        if let popoverPresentationController = alert.popoverPresentationController {
            popoverPresentationController.barButtonItem = sender
        }

        present(alert, animated: true, completion: nil)
    }

    @IBAction func flagButtonTapped(_ sender: UIBarButtonItem) {
        defer {
            updateFlaggedStatus()
        }

        guard let message = message else {
            return
        }

        if (message.imapFlags?.flagged == true) {
            message.imapFlags?.flagged = false
            delegate?.emailDisplayDidUnflag(message: message)
        } else {
            message.imapFlags?.flagged = true
            delegate?.emailDisplayDidFlag(message: message)
        }
        message.save()
    }


    @IBAction func moveToFolderButtonTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: .segueShowMoveToFolder, sender: self)
    }

    @IBAction func deleteButtonTapped(_ sender: UIBarButtonItem) {
        message?.imapDelete()
        if let message = message {
            delegate?.emailDisplayDidDelete(message: message)
        }
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

    @IBAction func showHandshakeView(gestureRecognizer: UITapGestureRecognizer) {
        if (splitViewController?.isCollapsed) ?? true {
            performSegue(withIdentifier: .segueHandshakeCollapsed, sender: self)

        } else {
            performSegue(withIdentifier: .segueHandshake, sender: self)

        }
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
        case segueHandshakeCollapsed
        case segueShowMoveToFolder
        case unwindToThread
        case noSegue
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let theId = segueIdentifier(for: segue)
        switch theId {
        case .segueReplyFrom, .segueReplyAllForm, .segueForward:
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
            }
        case .segueShowMoveToFolder:
            guard  let nav = segue.destination as? UINavigationController,
                let destination = nav.topViewController as? MoveToAccountViewController else {
                    Log.shared.errorAndCrash(component: #function, errorString: "No DVC?")
                    break
            }
            destination.appConfig = appConfig
            if let msg = message {
                destination.viewModel = MoveToAccountViewModel(messages: [msg])
            }
            destination.delegate = self
        case .segueHandshake, .segueHandshakeCollapsed:

            guard let destination = segue.destination as? HandshakeViewController,
            let titleView = navigationItem.titleView else {
                Log.shared.errorAndCrash(component: #function, errorString: "No DVC?")
                break
            }

            destination.popoverPresentationController?.delegate = self
            destination.popoverPresentationController?.sourceView = titleView
            destination.popoverPresentationController?.sourceRect = CGRect(x: titleView.bounds.midX,
                                                                           y:titleView.bounds.midY,
                                                                           width:0,
                                                                           height:0)
            destination.appConfig = appConfig
            destination.message = message
            destination.ratingReEvaluator = ratingReEvaluator
            break
        case .noSegue, .unwindToThread:
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

private extension Selector {
    static let okButtonPressed = #selector(EmailViewController.okButtonPressed(sender:))
}
