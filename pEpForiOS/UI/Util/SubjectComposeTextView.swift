//
//  SubjectComposeTextView.swift
//  pEp
//
//  Created by Dirk Zimmermann on 02.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

class SubjectComposeTextView: ComposeTextView {
    override func layoutAfterTextDidChange(tableView: UITableView) {
        tableView.updateSize() { [weak self] in
            if let theSelf = self {
                Timer.scheduledTimer(timeInterval: 0.01,
                                     target: theSelf,
                                     selector: #selector(theSelf.timerScroll),
                                     userInfo: tableView,
                                     repeats: false)
            }
        }
    }

    @objc func timerScroll(_ timer: Timer) {
        if let tableView = timer.userInfo as? UITableView {
            self.scrollCaretToVisible(containingTableView: tableView)
        }
    }
}
