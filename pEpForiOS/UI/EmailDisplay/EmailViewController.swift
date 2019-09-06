//
//  EmailViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 31/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit
import QuickLook

import pEpIOSToolbox
import MessageModel
import PEPObjCAdapterFramework

class EmailViewController: BaseTableViewController {
    @IBOutlet var flagButton: UIBarButtonItem!
    @IBOutlet var destructiveButton: UIBarButtonItem!
    @IBOutlet var previousMessage: UIBarButtonItem!
    @IBOutlet var nextMessage: UIBarButtonItem!
    @IBOutlet var moveToFolderButton: UIBarButtonItem!
    @IBOutlet var replyButton: UIBarButtonItem!

    var barItems: [UIBarButtonItem]?

    var message: Message?
    var folderShow: Folder?
    var messageId = 0

    var shouldShowOKButton: Bool = false

    private var partnerIdentity: Identity?
    private var tableData: ComposeDataSource?
    lazy private var backgroundQueue = OperationQueue()
    lazy private var documentInteractionController = UIDocumentInteractionController()

    lazy var clickHandler: UrlClickHandler = {
        return UrlClickHandler(actor: self, appConfig: appConfig)
    }()
    
    private var selectedAttachmentURL: URL?

    // MARK: - LIFE CYCLE

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSplitViewBackButton()
        configureOKButton()

        loadDatasource("MessageData")
        setupToolbar()

        tableView.estimatedRowHeight = 72.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureTableRows()
        configureView()
    }

    //MARK: - Temp fix to Beta

    private func hideNextAndPrevious() {
        //!!!:opacity in storyboard is now at 0% must be changed to enable this buttons again
        nextMessage.isEnabled = false
        previousMessage.isEnabled = false
    }

    // MARK: - UTIL

    private func updateFlaggedStatus() {
        changeFlagButtonTo(flagged: message?.imapFlags.flagged ?? false)
    }

    internal func changeFlagButtonTo(flagged: Bool) {
        if (flagged) {
            flagButton.image = UIImage(named: "icon-flagged")
        }
        else {
            flagButton.image = UIImage(named: "icon-unflagged")
        }
    }

    private func showPepRating() {
        guard let privacyStatusIcon = showPepRating(pEpRating: message?.pEpRating()) else {
            return
        }
        guard
            let handshakeCombos = message?.handshakeActionCombinations(), //!!!: EmailView must not know about handshakeCombinations.
            !handshakeCombos.isEmpty
            else {
                return
        }
        let tapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(showHandshakeView(gestureRecognizer:)))
        privacyStatusIcon.addGestureRecognizer(tapGestureRecognizer)
    }

    private final func loadDatasource(_ file: String) {
        if let path = Bundle.main.path(forResource: file, ofType: "plist") {
            if let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
                tableData = ComposeDataSource(with: dict["Rows"] as! [[String: Any]])
            }
        }
    }

    // MARK: - SETUP

    private func setupToolbar() {

        let item = UIBarButtonItem.getPEPButton(
            action: #selector(showSettingsViewController),
            target: self)
        item.tag = BarButtonType.settings.rawValue
        let flexibleSpace: UIBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace,
            target: nil,
            action: nil)
        flexibleSpace.tag = BarButtonType.space.rawValue
        toolbarItems?.append(contentsOf: [flexibleSpace,item])
    }

    func configureTableRows() {
        tableData?.filterRows(message: message)
    }

    func configureView() {
        // Make sure the NavigationBar is shown, even if the previous view has hidden it.
        navigationController?.setNavigationBarHidden(false, animated: false)

        title = NSLocalizedString("Message", comment: "Message view title")

        setupDestructiveButtonIcon()

        if messageId <= 0 {
            previousMessage.isEnabled = false
        } else {
            previousMessage.isEnabled = true
        }

        showPepRating()

        if let internalMessage = message, !internalMessage.imapFlags.seen {
            internalMessage.markAsSeen()
        }

        ///TODO: reimplement next-previous
        //        DispatchQueue.main.async {
        //
        //            if let total = self.folderShow?.messageCount(), self.messageId >= total - 1 {
        //                self.nextMessage.isEnabled = false
        //            } else {
        //                self.nextMessage.isEnabled = true
        //            }
        //        }
        updateFlaggedStatus()
    }

    private func configureSplitViewBackButton() {
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        navigationItem.leftItemsSupplementBackButton = true
    }

    private func configureOKButton() {
        if (shouldShowOKButton) {
            let okButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: .okButtonPressed)
            navigationItem.leftBarButtonItems? = [okButton]
            navigationItem.hidesBackButton = true
        }
    }

    @objc internal func okButtonPressed(sender: UIBarButtonItem) {
        performSegue(withIdentifier: .unwindToThread, sender: self) //!!!: rm, thread does not exist
    }

    // Sets the destructive bottom bar item accordint to the message (trash/archive)
    private func setupDestructiveButtonIcon() {
        guard let msg = message else {
            Log.shared.errorAndCrash("No message")
            return
        }

        if msg.parent.defaultDestructiveActionIsArchive {
            // Replace the Storyboard set trash icon for providers that use "archive" rather than
            // "delete" as default
            destructiveButton.image = #imageLiteral(resourceName: "folders-icon-archive")
        }
    }

    // MARK: - UISplitViewcontrollerDelegate

    func splitViewController(willChangeTo displayMode: UISplitViewController.DisplayMode) {
        switch displayMode {
        case .primaryHidden:
            var leftBarButtonItems: [UIBarButtonItem] = [nextMessage, previousMessage]
            if let unwrappedLeftBarButtonItems = navigationItem.leftBarButtonItems {
                leftBarButtonItems.append(contentsOf: unwrappedLeftBarButtonItems)
            }
            navigationItem.setLeftBarButtonItems(leftBarButtonItems.reversed(), animated: true)

            break
        case .allVisible:
            removePEPButtons()
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
                Log.shared.errorAndCrash("Cast error")
                return SecureWebViewController()
        }
        vc.zoomingEnabled = true
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
            Log.shared.errorAndCrash("No msg.")
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

    @objc private func showSettingsViewController() {
        splitViewController?.preferredDisplayMode = .allVisible
        guard let nav = splitViewController?.viewControllers.first as? UINavigationController,
            let vc = nav.topViewController else {
                return
        }
        UIUtils.presentSettings(on: vc, appConfig: appConfig)
    }

    @IBAction func next(_ sender: Any) {
        messageId += 1
        if let m = folderShow?.messageAt(index: messageId) {
            message = m
        }

        Log.shared.info("next, will reload table view")
        configureTableRows()
        tableView.reloadData()
        configureView()
    }

    @IBAction func previous(_ sender: Any) {
        messageId -= 1
        if let m = folderShow?.messageAt(index: messageId) {
            message = m
        }

        Log.shared.info("previous, will reload table view")
        configureTableRows()
        tableView.reloadData()
        configureView()
    }

    @IBAction func pressReply(_ sender: UIBarButtonItem) {
        // The ReplyAllPossibleChecker() should be pushed into the view model
        // as soon as there is one.
        let alert = ReplyAlertCreator(replyAllChecker: ReplyAllPossibleChecker())
            .withReplyOption { [weak self] action in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost MySelf")
                    return
                }
                me.performSegue(withIdentifier: .segueReplyFrom , sender: self)
            }.withReplyAllOption(forMessage: message) { [weak self] action in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost MySelf")
                    return
                }
                me.performSegue(withIdentifier: .segueReplyAllForm , sender: self)
            }.withFordwardOption { [weak self] action in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost MySelf")
                    return
                }
                me.performSegue(withIdentifier: .segueForward , sender: self)
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

        if (message.imapFlags.flagged == true) {
            let imap = message.imapFlags
            imap.flagged = false
            message.imapFlags = imap
        } else {
            let imap = message.imapFlags
            imap.flagged = true
            message.imapFlags = imap
        }
        message.save()
    }


    @IBAction func moveToFolderButtonTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: .segueShowMoveToFolder, sender: self)
    }

    @IBAction func deleteButtonTapped(_ sender: UIBarButtonItem) {
        guard let message = message else {
            Log.shared.errorAndCrash("No message")
            return
        }
        Message.imapDelete(messages: [message])
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
        Log.shared.info("cell for %d:%d", indexPath.section, indexPath.row)
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
                Log.shared.errorAndCrash("Missing data")
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
                    Log.shared.errorAndCrash("No DVC?")
                    break
            }
            destination.appConfig = appConfig
            destination.viewModel = ComposeViewModel(resultDelegate: nil,
                                                     composeMode: composeMode(for: theId),
                                                     prefilledTo: nil,
                                                     originalMessage: message)
        case .segueShowMoveToFolder:
            guard  let nav = segue.destination as? UINavigationController,
                let destination = nav.topViewController as? MoveToAccountViewController else {
                    Log.shared.errorAndCrash("No DVC?")
                    break
            }
            destination.appConfig = appConfig
            if let msg = message {
                destination.viewModel = MoveToAccountViewModel(messages: [msg])
            }
        case .segueHandshake, .segueHandshakeCollapsed:

            guard let nv = segue.destination as? UINavigationController,
                let vc = nv.topViewController as? HandshakeViewController,
                let titleView = navigationItem.titleView else {
                Log.shared.errorAndCrash("No DVC?")
                break
            }

            guard let message = message else {
                Log.shared.errorAndCrash("No message")
                return
            }

            nv.popoverPresentationController?.delegate = self
            nv.popoverPresentationController?.sourceView = titleView
            nv.popoverPresentationController?.sourceRect = CGRect(x: titleView.bounds.midX,
                                                                  y: titleView.bounds.midY,
                                                                  width: 0,
                                                                  height: 0)
            vc.appConfig = appConfig
            vc.message = message
            vc.ratingReEvaluator = RatingReEvaluator(message: message)
            break
        case .noSegue, .unwindToThread:
            break
        }
    }

    private func composeMode(for segueId: SegueIdentifier) -> ComposeUtil.ComposeMode {
        if segueId == .segueReplyFrom {
            return .replyFrom
        } else if segueId == .segueReplyAllForm {
            return  .replyAll
        } else if segueId == .segueForward {
            return  .forward
        } else {
            Log.shared.errorAndCrash("Unsupported input")
            return .replyFrom
        }
    }

    private func removePEPButtons() {
        guard let isCollapsed = splitViewController?.isCollapsed else {
            return
        }

        let useToolbarItemsDirectly = traitCollection.verticalSizeClass == .regular

        var barButtonItems = useToolbarItemsDirectly ?
            toolbarItems ?? [] : navigationItem.rightBarButtonItems ?? []

        if !isCollapsed {
            var itemsToRemove = [UIBarButtonItem]()
            for item in barButtonItems {
                if item.tag == BarButtonType.settings.rawValue {
                    itemsToRemove.append(item)
                }
            }

            for itemToRemove in itemsToRemove {
                var positionToRemove: Int? = nil

                for i in 0..<barButtonItems.count {
                    if barButtonItems[i] == itemToRemove {
                        positionToRemove = i
                        break
                    }
                }

                if let thePosition = positionToRemove {
                    barButtonItems.remove(at: thePosition)
                }
            }

            if useToolbarItemsDirectly {
                toolbarItems = barButtonItems
            } else {
                navigationItem.rightBarButtonItems = barButtonItems
            }
        }
    }

    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        if UI_USER_INTERFACE_IDIOM() == .pad {
            documentInteractionController.dismissMenu(animated: false)
        }

        splitViewController?.preferredDisplayMode = .allVisible

        coordinator.animate(alongsideTransition: nil)
    }
}

// MARK: - MessageAttachmentDelegate

extension EmailViewController: MessageAttachmentDelegate {

    func didTap(cell: MessageCell, attachment: Attachment, location: CGPoint, inView: UIView?) {
        let busyState = inView?.displayAsBusy()
        let attachmentOp = AttachmentToLocalURLOperation(attachment: attachment)
        attachmentOp.completionBlock = { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            GCD.onMain {
                defer {
                    if let bState = busyState {
                        inView?.stopDisplayingAsBusy(viewBusyState: bState)
                    }
                }
                guard let url = attachmentOp.fileURL else { //!!!: looks suspicously like retain cycle. attachmentOp <-> completionBlock
                    return
                }
                let safeAttachment = attachment.safeForSession(Session.main)
                me.didCreateLocally(attachment: safeAttachment,
                                       url: url,
                                       cell: cell,
                                       location: location,
                                       inView: inView)
            }
        }
        backgroundQueue.addOperation(attachmentOp)
    }

    private func didCreateLocally(attachment: Attachment,
                                  url: URL,
                                  cell: MessageCell,
                                  location: CGPoint,
                                  inView: UIView?) {
        let mimeType = MimeTypeUtils.findBestMimeType(forFileAt: url,
                                                      withGivenMimeType: attachment.mimeType)
        if mimeType == MimeTypeUtils.MimesType.pdf
            && QLPreviewController.canPreview(url as QLPreviewItem) {
            selectedAttachmentURL = url
            let previewController = QLPreviewController()
            previewController.dataSource = self
            present(previewController, animated: true, completion: nil)
        } else {
            documentInteractionController.url = url
            let theView = inView ?? cell
            let dim: CGFloat = 40
            let rect = CGRect.rectAround(center: location, width: dim, height: dim)
            documentInteractionController.presentOptionsMenu(from: rect,
                                                             in: theView,
                                                             animated: true)
        }
    }
}

extension EmailViewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        guard let url = selectedAttachmentURL else {
            fatalError("Could not load URL")
        }
        return url as QLPreviewItem
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

enum BarButtonType: Int {
    case space = 1
    case settings = 2
}
