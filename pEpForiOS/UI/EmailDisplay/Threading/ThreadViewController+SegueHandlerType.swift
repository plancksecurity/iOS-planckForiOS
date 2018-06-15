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
        case segueShowEmail
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueId = segueIdentifier(for: segue)
        switch segueId {
        case .segueShowEmail:
            guard let vc = segue.destination as? EmailViewController,
                let appConfig = self.appConfig,
                let indexPath = tableView.indexPathForSelectedRow /*,
                let message = model?.message(representedByRowAt: indexPath) */ else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Segue issue")
                    return
            }
            vc.appConfig = appConfig
//            vc.message = message
//            vc.folderShow = folderToShow
//            vc.messageId = indexPath.row //that looks wrong
//            vc.delegate = model
//            model?.currentDisplayedMessage = vc
        default:
            Log.shared.errorAndCrash(component: #function, errorString: "Unhandled segue")
            break
        }
    }

}
