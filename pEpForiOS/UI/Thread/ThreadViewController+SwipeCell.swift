// Message threadding is currently umsupported. The code might be helpful. 

////
////  ThreadViewController+SwipeCell.swift
////  pEp
////
////  Created by Miguel Berrocal Gómez on 21/06/2018.
////  Copyright © 2018 p≡p Security S.A. All rights reserved.
////
//
//import Foundation
//import SwipeCellKit
//
//extension ThreadViewController: SwipeTableViewCellDelegate {
//
//    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
//        var swipeActions = [SwipeAction]()
//
//        // Delete or Archive
//        swipeActions.append(deleteAction())
//
//        //Get from model
//        let draftFolder = false
//        if !draftFolder {
//            swipeActions.append(flagAction())
//            swipeActions.append(replyAction())
//        }
//
//        return (orientation == .right ?   swipeActions : nil)
//    }
//
//    func visibleRect(for tableView: UITableView) -> CGRect? {
//        let topInset = navigationController?.navigationBar.frame.height ?? 0
//        let bottomInset = navigationController?.toolbar?.frame.height ?? 0
//        let bounds = tableView.bounds
//
//        return CGRect(x: bounds.origin.x, y: bounds.origin.y + topInset, width: bounds.width, height: bounds.height - bottomInset)
//    }
//
//    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
//        var options = SwipeOptions()
//        options.expansionStyle = .destructive(automaticallyDelete: false)
//        options.buttonSpacing = 4
//        options.transitionStyle = .border
//        options.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
//
//        return options
//    }
//
//    private func configure(action: SwipeAction, with descriptor: SwipeActionDescriptor) {
//        let buttonStyle: ButtonStyle = .circular
//        let buttonDisplayMode: ButtonDisplayMode = .imageOnly
//        action.title = descriptor.title(forDisplayMode: buttonDisplayMode)
//        action.image = descriptor.image(forStyle: buttonStyle, displayMode: buttonDisplayMode)
//        action.backgroundColor = .clear
//        action.textColor = descriptor.color
//        action.font = .systemFont(ofSize: 13)
//        action.transitionDelegate = ScaleTransition.default
//    }
//
//    private func deleteAction() -> SwipeAction {
//        let defaultIsArchive = false //!!!: Looks wrong!
//        let titleDestructive = defaultIsArchive ? "Archive" : "Delete"
//        let descriptorDestructive: SwipeActionDescriptor = defaultIsArchive ? .archive : .trash
//        let archiveAction =
//            SwipeAction(style: .destructive, title: titleDestructive) {action, indexPath in
//                self.tableView.beginUpdates()
//                self.model?.deleteMessage(at: indexPath.section)
//                action.fulfill(with: .delete)
//                self.tableView.endUpdates()
//        }
//        configure(action: archiveAction, with: descriptorDestructive)
//        return archiveAction
//    }
//
//    private func flagAction() -> SwipeAction {
//        // Do not add "Flag" action to drafted mails.
//        let flagAction = SwipeAction(style: .default, title: "Flag") { action, indexPath in
//            self.model.switchFlag(forMessageAt: indexPath.section)
//
//            guard let cell = self.tableView.cellForRow(at: indexPath) else {
//                return
//            }
//            self.flagCell(cell: cell)
//        }
//        flagAction.hidesWhenSelected = true
//        configure(action: flagAction, with: .flag)
//        return flagAction
//    }
//
//    private func flagCell(cell: UITableViewCell) {
//        if let cell = cell as? EmailListViewCell {
//            cell.isFlagged = !cell.isFlagged
//        }
//        else if let cell = cell as? FullMessageCell {
//            cell.isFlagged = !cell.isFlagged
//        }
//    }
//
//    private func replyAction() -> SwipeAction {
//        // Do not add reply action to drafted mails.
//        let moreAction = SwipeAction(style: .default, title: "Reply") { action, indexPath in
//            self.model.replyToMessage(at: indexPath.section)
//            self.performSegue(withIdentifier: .segueReplyAllForm , sender: self)
//        }
//        moreAction.hidesWhenSelected = true
//        configure(action: moreAction, with: .reply)
//        return moreAction
//    }
//
//
//}
