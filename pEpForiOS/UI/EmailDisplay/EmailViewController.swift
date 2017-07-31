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

class EmailViewController: UITableViewController {
    var appConfig: AppConfig!

    var message: Message!

    var partnerIdentity: Identity?
    var tableData: ComposeDataSource?
    var folderShow : Folder?
    var messageId = 0
    var otherCellsHeight: CGFloat = 0.0
    var ratingReEvaluator: RatingReEvaluator?

    lazy var backgroundQueue = OperationQueue()
    lazy var documentInteractionController = UIDocumentInteractionController()

    @IBOutlet var previousMessage: UIBarButtonItem!
    @IBOutlet var nextMessage: UIBarButtonItem!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        loadDatasource("MessageData")

        tableView.estimatedRowHeight = 72.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
        
        guard
            let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let config = appDelegate.appConfig
            else {
                #if DEBUG
                    fatalError()
                #else
                    return
                #endif
        }
        appConfig = config

        self.title = NSLocalizedString("Message", comment: "Message view title")
    }


    @IBAction func next(_ sender: Any) {
        messageId += 1
        message = folderShow?.messageAt(index: messageId)
        self.tableView.reloadData()
        configureView()
        
    }
    
    @IBAction func previous(_ sender: Any) {
        messageId -= 1
        message = folderShow?.messageAt(index: messageId)
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
        checkMessageReEvaluation()
        showPepRating()
        message.markAsSeen()
        if messageId <= 0 {
            self.previousMessage.isEnabled = false
        } else {
            self.previousMessage.isEnabled = true
        }
        if let total = folderShow?.messageCount(), messageId >= total - 1 {
            self.nextMessage.isEnabled = false
        } else {
            self.nextMessage.isEnabled = true
        }
    }

    func checkMessageReEvaluation() {
        if ratingReEvaluator?.message != message {
            ratingReEvaluator = RatingReEvaluator(parentName: #function, message: message)
            ratingReEvaluator?.delegate = self
        }
    }

    func showPepRating() {
        let _ = showPepRating(pEpRating: message.pEpRating(session: nil))
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
        if (message.imapFlags?.flagged == true) {
            message.imapFlags?.flagged = false
        } else {
            message.imapFlags?.flagged = true
        }
        message.save()
    }
    
    @IBAction func archiveButtonTapped(_ sender: UIBarButtonItem) {
        //TODO: stubbed method
    }
    
    @IBAction func deleteButtonTapped(_ sender: UIBarButtonItem) {
        message.delete() // mark for deletion/trash
        message.save()
        _ = navigationController?.popViewController(animated: true)
    }
    
    /**
     For the unwind segue from the trustwords controller, when the user choses "trusted".
     */
    @IBAction func segueUnwindTrusted(segue: UIStoryboardSegue) {
        if let p = partnerIdentity {
            PEPUtil.trust(identity: p)
            decryptAgain()
        }
    }

    /**
     For the unwind segue from the trustwords controller, when the user choses "untrusted".
     */
    @IBAction func segueUnwindUnTrusted(segue: UIStoryboardSegue) {
        if let p = partnerIdentity {
            PEPUtil.mistrust(identity: p)
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
                for: indexPath) as? MessageCell else {
                    return UITableViewCell()
        }
        cell.updateCell(model: row, message: message, indexPath: indexPath)
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
        case noSegue
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .segueReplyFrom:
            if let nav = segue.destination as? UINavigationController,
                let destination = nav.topViewController as? ComposeTableViewController {
                destination.composeMode = .replyFrom
                destination.appConfig = appConfig
                destination.originalMessage = message
            }
            break
        case .segueReplyAllForm:
            if let nav = segue.destination as? UINavigationController,
                let destination = nav.topViewController as? ComposeTableViewController {
                destination.composeMode = .replyAll
                destination.appConfig = appConfig
                destination.originalMessage = message
            }
            break
        case .segueForward:
            let destination = segue.destination as? ComposeTableViewController
            destination?.composeMode = .forward
            destination?.appConfig = appConfig
            destination?.originalMessage = message
            break
        case .segueHandshake:
            let destination = segue.destination as? HandshakeViewController
            destination?.message = message
            destination?.appConfig = appConfig
            destination?.ratingReEvaluator = ratingReEvaluator
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
