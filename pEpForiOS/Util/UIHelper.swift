//
//  UIHelper.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 01/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

class UIHelper {
    static func variableCellHeightsTableView(tableView: UITableView) {
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
    }

    static func labelFromContact(contact: Contact) -> UILabel {
        let l = UILabel.init()
        l.text = contact.displayString()
        return l
    }

}