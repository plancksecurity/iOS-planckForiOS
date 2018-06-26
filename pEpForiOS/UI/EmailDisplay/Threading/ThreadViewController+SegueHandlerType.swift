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
        case SegueShowEmail
        case SegueShowEmailExpanding
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueId = segueIdentifier(for: segue)
        switch segueId {
        case .SegueShowEmail, .SegueShowEmailExpanding:
            guard let nav = segue.destination as? UINavigationController,
                let vc = nav.rootViewController as? EmailViewController,
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
        default:
            Log.shared.errorAndCrash(component: #function, errorString: "Unhandled segue")
            break
        }
    }

}
