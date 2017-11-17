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
    @IBOutlet var handShakeButton: UIBarButtonItem!
    @IBOutlet var flagButton: UIBarButtonItem!
    @IBOutlet var previousMessage: UIBarButtonItem!
    @IBOutlet var nextMessage: UIBarButtonItem!

    var message: Message?

    var partnerIdentity: Identity?
    var tableData: ComposeDataSource?
    var folderShow : Folder?
    var messageId = 0
    var otherCellsHeight: CGFloat = 0.0
    var ratingReEvaluator: RatingReEvaluator?

    lazy var backgroundQueue = OperationQueue()
    lazy var documentInteractionController = UIDocumentInteractionController()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let m = message else{
            Log.shared.errorAndCrash(component: #function, errorString: "no message to show")
            return
        }

        loadDatasource("MessageData")

        tableView.estimatedRowHeight = 72.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()

        self.title = m.shortMessage
        saveTitleView()
    }

    @IBAction func next(_ sender: Any) {
        messageId += 1
        if let m = folderShow?.messageAt(index: messageId) {
            message = m
        }
        //message =
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setNoColor()
    }

    func configureView() {
        tableData?.filterRows(message: message)

        recoveryInitialTitle()

        if messageId <= 0 {
            self.previousMessage.isEnabled = false
        } else {
            self.previousMessage.isEnabled = true
        }

        DispatchQueue.main.async {
            self.checkMessageReEvaluation()
            self.showPepRating()

            self.message?.markAsSeen()

            if let total = self.folderShow?.messageCount(), self.messageId >= total - 1 {
                self.nextMessage.isEnabled = false
            } else {
                self.nextMessage.isEnabled = true
            }
        }
        updateFlaggedStatus()
    }

    func updateFlaggedStatus() {
        if message?.imapFlags?.flagged ?? false {
            flagButton.image = UIImage.init(named: "icon-flagged")
        } else {
            flagButton.image = UIImage.init(named: "icon-unflagged")
        }
    }

    func checkMessageReEvaluation() {
        if let m = message, ratingReEvaluator?.message != m {
            ratingReEvaluator = RatingReEvaluator(parentName: #function, message: m)
            ratingReEvaluator?.delegate = self
        }
    }

    func showPepRating() {
        let session = PEPSession()
        let _ = showPepRating(pEpRating: message?.pEpRating(session: session))
        var allOwnKeysGenerated = true
        var atLeastOneHandshakableIdentityFound = false
        if let m = message {
            for id in m.allIdentities {
                if id.isMySelf {
                    // if we encounter an own identity, make sure it already has a key
                    if id.fingerPrint(session: session) == nil {
                        allOwnKeysGenerated = false
                        break
                    }
                } else {
                    if id.canHandshakeOn(session: session) {
                        atLeastOneHandshakableIdentityFound = true
                        break
                    }
                }
            }
        }
        handShakeButton.isEnabled = allOwnKeysGenerated && atLeastOneHandshakableIdentityFound
    }

    fileprivate final func loadDatasource(_ file: String) {
        if let path = Bundle.main.path(forResource: file, ofType: "plist") {
            if let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
                tableData = ComposeDataSource(with: dict["Rows"] as! [[String: Any]])
            }
        }
    }

    // MARK: - IBActions

    @IBAction func pressReply(_ sender: UIBarButtonItem) {
        let alertViewWithoutTitle = UIAlertController()
        alertViewWithoutTitle.view.tintColor = .pEpGreen

        if let popoverPresentationController = alertViewWithoutTitle.popoverPresentationController {
            popoverPresentationController.sourceView = view
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

    @IBAction func deleteButtonTapped(_ sender: UIBarButtonItem) {
        message?.delete() // mark for deletion/trash
        _ = navigationController?.popViewController(animated: true)
    }

    /**
     For the unwind segue from the trustwords controller, when the user choses "trusted".
     */
    @IBAction func segueUnwindTrusted(segue: UIStoryboardSegue) {
        if let p = partnerIdentity {
            let session = PEPSession()
            PEPUtil.trust(identity: p, session: session)
            decryptAgain()
        }
    }

    /**
     For the unwind segue from the trustwords controller, when the user choses "untrusted".
     */
    @IBAction func segueUnwindUnTrusted(segue: UIStoryboardSegue) {
        if let p = partnerIdentity {
            let session = PEPSession()
            PEPUtil.mistrust(identity: p, session: session)
            decryptAgain()
        }
    }

    func decryptAgain() {
        ratingReEvaluator?.reevaluateRating()
    }
}

// MARK: UITableViewDataSource

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
        cell.updateCell(model: row, message: m, indexPath: indexPath)
        cell.delegate = self
        return cell
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
            self.title = NSLocalizedString("Message", comment: "Message view title")
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
        GCD.onMain {
            self.showPepRating()
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
            if let url = attachmentOp.fileURL {
                GCD.onMain {
                    if let bState = busyState {
                        inView?.stopDisplayingAsBusy(viewBusyState: bState)
                    }
                    self?.didCreateLocally(attachment: attachment, url: url, cell: cell,
                                           location: location, inView: inView)
                }
            }
        }
        backgroundQueue.addOperation(attachmentOp)
    }
}

// MARK: - Title View Extension

extension EmailViewController {

    func saveTitleView() {
        self.originalTitleView = self.title
    }

    func recoveryInitialTitle() {
        self.navigationItem.titleView = nil
        self.navigationItem.title = self.originalTitleView
        self.title = self.originalTitleView
    }

}
