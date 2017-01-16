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
    var tableData: ComposeDataSource?
    var datasource = [Message]()
    var page = 0
    var otherCellsHeight: CGFloat = 0.0
    var computedHeight: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadDatasource("MessageData")
        
        tableView.estimatedRowHeight = 72.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
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
        
        if let popoverPresentationController = alertViewWithoutTitle.popoverPresentationController {
            popoverPresentationController.sourceView = view
        }

        let alertActionReply = UIAlertAction (title: "Reply".localized, style: .default) { (action) in
            self.performSegue(withIdentifier: .segueReplyFrom , sender: self)
        }
        alertViewWithoutTitle.addAction(alertActionReply)

        let alertActionForward = UIAlertAction (title: "Forward".localized, style: .default) { (action) in
            self.performSegue(withIdentifier: .segueForward , sender: self)
        }
        alertViewWithoutTitle.addAction(alertActionForward)

        let cancelAction = UIAlertAction(title: "Cancel".localized, style: .cancel) { (action) in }
        alertViewWithoutTitle.addAction(cancelAction)

        present(alertViewWithoutTitle, animated: true, completion: nil)
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
        case segueForward
        case segueTrustWords
        case seguePrevious
        case segueNext
        case noSegue
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
        case .noSegue:
            break
        }
    }
}

