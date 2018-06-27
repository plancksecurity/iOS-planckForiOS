//
//  ThreadViewController+SegueHandlerType.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 15/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
extension ThreadViewController: SegueHandlerType {

    enum SegueIdentifier: String {
        case segueShowMoveToFolder
        case segueShowEmail
        case segueShowEmailExpanding
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueId = segueIdentifier(for: segue)
        switch segueId {
        case .segueShowEmail, .segueShowEmailExpanding:
//            guard let nav = segue.destination as? UINavigationController,
                guard let vc = segue.destination as? EmailViewController,
                let appConfig = self.appConfig,
                let indexPath = tableView.indexPathForSelectedRow,
                let message = model?.message(at: indexPath.section) else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Segue issue")
                    return
            }
            vc.appConfig = appConfig

            vc.message = message
            vc.folderShow = model?.displayFolder
            vc.messageId = indexPath.row
        case .segueShowMoveToFolder:
            guard  let nav = segue.destination as? UINavigationController,
                let destination = nav.topViewController as? MoveToAccountViewController else {
                    Log.shared.errorAndCrash(component: #function, errorString: "No DVC?")
                    break
            }
            destination.appConfig = appConfig
            if let messages = model?.messages {
                destination.viewModel = MoveToAccountViewModel(messages: messages)
            }
            destination.delegate = model
        default:
            Log.shared.errorAndCrash(component: #function, errorString: "Unhandled segue")
            break
        }
    }

}
