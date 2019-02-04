//
//  ThreadViewController+SegueHandlerType.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 15/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpUtilities

extension ThreadViewController: SegueHandlerType {

    enum SegueIdentifier: String {
        case segueShowMoveToFolder
        case segueReplyFrom
        case segueReplyAllForm
        case segueForward
        case segueShowEmail
        case segueShowEmailExpanding
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueId = segueIdentifier(for: segue)
        switch segueId {
        case .segueShowEmail, .segueShowEmailExpanding:
                guard let vc = segue.destination as? EmailViewController,
                let appConfig = self.appConfig,
                let indexPath = tableView.indexPathForSelectedRow,
                let message = model?.message(at: indexPath.section) else {
                    Logger.frontendLogger.errorAndCrash("Segue issue")
                    return
            }
            vc.appConfig = appConfig
            vc.shouldShowOKButton = !isSplitViewControllerCollapsed()
            vc.message = message
            vc.folderShow = model?.displayFolder
            vc.messageId = indexPath.row
            vc.delegate = model
            model.currentDisplayedMessage = vc
        case .segueShowMoveToFolder:
            guard  let nav = segue.destination as? UINavigationController,
                let destination = nav.topViewController as? MoveToAccountViewController else {
                    Logger.frontendLogger.errorAndCrash("No DVC?")
                    break
            }
            destination.appConfig = appConfig
            if let messages = model?.messages {
                destination.viewModel = MoveToAccountViewModel(messages: messages)
            }
            destination.delegate = model
            model.didMove()
        case .segueReplyFrom, .segueReplyAllForm, .segueForward:
            guard  let nav = segue.destination as? UINavigationController,
                let destination = nav.topViewController as? ComposeTableViewController,
                let appConfig = appConfig else {
                    Logger.frontendLogger.errorAndCrash("No DVC?")
                    break
            }
            destination.appConfig = appConfig

            // Commented as it does not fit new MVVM ComposeVC any more.
            // See Email[List]ViewController.
//            if segueId == .segueReplyFrom {
//                destination.composeMode = .replyFrom
//                destination.originalMessage = model.getMessageToReply()
//            } else if segueId == .segueReplyAllForm {
//                destination.composeMode = .replyAll
//                destination.originalMessage =  model.getMessageToReply()
//            } else if segueId == .segueForward {
//                destination.composeMode = .forward
//                destination.originalMessage =  model.getMessageToReply()
//            }
        }
    }

}
