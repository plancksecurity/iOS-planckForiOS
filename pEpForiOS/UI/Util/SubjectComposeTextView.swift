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
        scrollUtil.layoutAfterTextDidChange(tableView: tableView, textView: self)
    }
}
