//
//  EmailListViewController+EmailDisplayDelegate.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 28/05/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

extension EmailListViewController: EmailDisplayDelegate {

    func emailDisplayDidFlagMessage(emailViewController: EmailViewController) {
        let indexPath = IndexPath(row: emailViewController.messageId, section: 0)
        flagAction(forCellAt: indexPath)
    }

    func emailDisplayDidUnflagMessage(emailViewController: EmailViewController) {
        let indexPath = IndexPath(row: emailViewController.messageId, section: 0)
        flagAction(forCellAt: indexPath)
    }

    func emailDisplayDidDeleteMessage(emailViewController: EmailViewController) {
        guard let splitViewController = self.splitViewController else {
            return
        }
        if splitViewController.isCollapsed {
            navigationController?.popViewController(animated: true)
        } else {
            self.performSegue(withIdentifier: "showNoMessage", sender: nil)
        }
    }
}

