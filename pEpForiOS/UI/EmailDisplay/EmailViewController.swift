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
    var partnerIdentity: Identity!
    var tableData: ComposeDataSource?
    var datasource = [Message]()
    var page = 0
    var otherCellsHeight: CGFloat = 0.0
    var computedHeight: CGFloat = 0.0
    var defaultToolbarColor: UIColor?
    var defaultNavigationColor: UIColor?

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
        storeDefaultBarColors()
        showPepRating()
        self.title = message.shortMessage
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setDefaultBarColors()
    }

    func showPepRating() {
        // color
        if let color = message.pEpRating()?.uiColor() {
            navigationController?.navigationBar.barTintColor = color
            navigationController?.toolbar.barTintColor = color
        } else {
            setDefaultBarColors()
        }

        // icon
        if let img = message.pEpRating()?.pepColor().statusIcon() {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: img, style: .plain, target: nil, action: nil)
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    func storeDefaultBarColors() {
        defaultNavigationColor = navigationController?.navigationBar.barTintColor
        defaultToolbarColor = navigationController?.toolbar.barTintColor
    }
    
    func setDefaultBarColors() {
        navigationController?.navigationBar.barTintColor = defaultNavigationColor
        navigationController?.toolbar.barTintColor = defaultToolbarColor
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

        let alertActionReply = UIAlertAction (title: "Reply".localized, style: .default) { (action) in
            self.performSegue(withIdentifier: .segueReplyFrom , sender: self)
        }
        alertViewWithoutTitle.addAction(alertActionReply)

        let alertActionReplyAll = UIAlertAction (title: "Reply.All".localized, style: .default) { (action) in
            self.performSegue(withIdentifier: .segueReplyAllForm , sender: self)
        }
        alertViewWithoutTitle.addAction(alertActionReplyAll)

        let alertActionForward = UIAlertAction (title: "Forward".localized, style: .default) { (action) in
            self.performSegue(withIdentifier: .segueForward , sender: self)
        }
        alertViewWithoutTitle.addAction(alertActionForward)

        let cancelAction = UIAlertAction(title: "Cancel".localized, style: .cancel) { (action) in }
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
    }
    
    @IBAction func deleteButtonTapped(_ sender: UIBarButtonItem) {
        message.delete() // mark for deletion/trash
        message.save()
        _ = navigationController?.popViewController(animated: true)
    }
    
    @IBAction func composeButtonTapped(_ sender: UIBarButtonItem) {
    }
    
    @IBAction func showRatingPressed(_ sender: UIBarButtonItem) {
        let filtered = message.identitiesEligibleForHandshake(session: appConfig.session)

        partnerIdentity = nil
        if filtered.count == 1 {
            partnerIdentity = filtered.first
            performSegue(withIdentifier: .segueTrustwords, sender: self)
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
        }
    }

    /**
     For the unwind segue from the trustwords controller, when the user choses "untrusted".
     */
    @IBAction func segueUnwindUnTrusted(segue: UIStoryboardSegue) {
        if let p = partnerIdentity {
            PEPUtil.mistrust(identity: p)
        }
    }
}

// MARK: TableView Delegate & Datasource

extension EmailViewController {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let row = tableData?.getRow(at: indexPath.row) else { return UITableViewAutomaticDimension }
        
        if row.display == .conditional {
            return 0
        }
        
        otherCellsHeight += row.height
        if indexPath.row == (tableData?.numberOfRows())! - 1 {
            let availableSpace = tableView.bounds.size.height - otherCellsHeight + 94.0
            if computedHeight > 0 {
                if availableSpace < computedHeight {
                    return computedHeight
                }
            }
            return (availableSpace > row.height) ? availableSpace : row.height
        }
        
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData?.numberOfRows() ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = tableData?.getRow(at: indexPath.row) else { return UITableViewCell() }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: row.identifier, for: indexPath) as! MessageCell
        cell.updateCell(row, message)
        cell.delegate = self
        
        return cell
    }
}

// MARK: - MessageContentCellDelegate

extension EmailViewController: MessageContentCellDelegate {
    func cellDidUpdateHeight(_ with: CGFloat) {
        computedHeight = with
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
            break
        case .segueTrustwords:
            let destination = segue.destination as? TrustwordsTableViewController
            destination?.message = message
            destination?.appConfig = appConfig
            destination?.myselfIdentity = PEPUtil.mySelf(message: message)
            destination?.partnerIdentity = partnerIdentity
            break
        case .noSegue:
            break
        }
    }
}

