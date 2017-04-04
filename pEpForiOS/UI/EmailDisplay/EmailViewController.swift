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

class EmailViewController: UITableViewController, AttachmentsViewHelperDelegate {
    var appConfig: AppConfig!

    var message: Message! {
        didSet {
            attachmentsViewHelper?.message = message
        }
    }

    var partnerIdentity: Identity?
    var tableData: ComposeDataSource?
    var datasource = [Message]()
    var page = 0
    var otherCellsHeight: CGFloat = 0.0
    var ratingReEvaluator: RatingReEvaluator?
    var lastHeights = [IndexPath: CGFloat]()
    var attachmentsViewHelper: AttachmentsViewHelper?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        attachmentsViewHelper = AttachmentsViewHelper(delegate: self)
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkMessageReEvaluation()
        showPepRating()
        message.markAsSeen()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setNoColor()
        lastHeights.removeAll()
    }

    func checkMessageReEvaluation() {
        if ratingReEvaluator?.message != message {
            ratingReEvaluator = RatingReEvaluator(message: message)
            ratingReEvaluator?.delegate = self
        }
    }

    func showPepRating() {
        let _ = showPepRating(pEpRating: message.pEpRating())
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
        title: "Reply".localized, style: .default) { (action) in
            self.performSegue(withIdentifier: .segueReplyFrom , sender: self)
        }
        alertViewWithoutTitle.addAction(alertActionReply)

        let alertActionReplyAll = UIAlertAction(
        title: "Reply.All".localized, style: .default) { (action) in
            self.performSegue(withIdentifier: .segueReplyAllForm , sender: self)
        }
        alertViewWithoutTitle.addAction(alertActionReplyAll)

        let alertActionForward = UIAlertAction(
        title: "Forward".localized, style: .default) { (action) in
            self.performSegue(withIdentifier: .segueForward , sender: self)
        }
        alertViewWithoutTitle.addAction(alertActionForward)

        let cancelAction = UIAlertAction(
        title: "Cancel".localized, style: .cancel) { (action) in }
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
    
    @IBAction func showRatingPressed(_ sender: UIBarButtonItem) {
        let filtered = message.identitiesEligibleForHandshake(session: appConfig.session)

        partnerIdentity = nil
        if filtered.count == 1, let partnerID = filtered.first {
            partnerIdentity = partnerID
            if partnerID.canResetTrust(session: appConfig.session) {
                // reset trust
                performSegue(withIdentifier: .seguePrivacyStatus, sender: self)
            } else {
                performSegue(withIdentifier: .segueTrustwords, sender: self)
            }
        } else if filtered.count > 1 || filtered.count == 0 {
            performSegue(withIdentifier: .seguePrivacyStatus, sender: self)
        }
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
        ratingReEvaluator?.decryptAgain()
    }
}

// MARK: UITableViewDelegate

extension EmailViewController {
    override func tableView(_ tableView: UITableView,
                            heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let height = lastHeights[indexPath] {
            return height
        }
        return UITableViewAutomaticDimension
    }

    override func tableView(_ tableView: UITableView,
                            heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {
            if let _ = attachmentsViewHelper?.resultView as? UIStackView {
                return 0
            }
        }
        return 0
    }

    override func tableView(_ tableView: UITableView,
                            viewForFooterInSection section: Int) -> UIView? {
        if section == 0 {
            if let view = attachmentsViewHelper?.resultView {
                return view
            }
        }
        return nil
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
        lastHeights[indexPath] = cell.height
        cell.delegate = self
        return cell
    }
}

// MARK: - AttachmentsViewHelperDelegate

extension EmailViewController {
    func didCreate(attachmentsView: UIView?, message: Message) {
        GCD.onMain {
            self.tableView.reloadData()
        }
    }
}

// MARK: - MessageContentCellDelegate

extension EmailViewController: MessageContentCellDelegate {
    func didUpdate(cell: MessageCell, height: CGFloat) {
        if let ip = cell.indexPath {
            lastHeights[ip] = height
        } else {
            lastHeights.removeAll()
        }
        tableView.updateSize(true)
    }
}

// MARK: - SegueHandlerType

extension EmailViewController: SegueHandlerType {
    enum SegueIdentifier: String {
        case segueReplyFrom
        case segueReplyAllForm
        case segueForward
        case seguePrevious
        case segueNext
        case segueTrustwords
        case seguePrivacyStatus
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
        case .seguePrevious:
            let destination = segue.destination as! EmailViewController
            if page > 0 { page -= 1 }
            destination.message = message
            destination.appConfig = appConfig
            break
        case .segueNext:
            let destination = segue.destination as! EmailViewController
            if page < datasource.count  { page += 1 }
            destination.message = message
            destination.appConfig = appConfig
            destination.page = page
            break
        case .seguePrivacyStatus:
            let destination = segue.destination as? PrivacyStatusTableViewController
            destination?.message = message
            destination?.appConfig = appConfig
            destination?.ratingReEvaluator = ratingReEvaluator
            break
        case .segueTrustwords:
            let destination = segue.destination as? TrustwordsTableViewController
            destination?.message = message
            destination?.appConfig = appConfig
            destination?.myselfIdentity = PEPUtil.ownIdentity(message: message)
            destination?.partnerIdentity = partnerIdentity
            break
        case .noSegue:
            break
        }
    }
}

extension EmailViewController: RatingReEvaluatorDelegate {
    func ratingChanged(message: Message) {
        GCD.onMain {
            self.showPepRating()
        }
    }
}
