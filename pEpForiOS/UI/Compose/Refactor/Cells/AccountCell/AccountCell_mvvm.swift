//
//  AccountCell_mvvm.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

//IOS-1369: rename and get rid of other
class AccountCell_mvvm: UITableViewCell {
    static let reuseId = "AccountCell_mvvm"
    @IBOutlet weak public var textView: UITextView!
    @IBOutlet weak public var titleLabel: UILabel!
}
