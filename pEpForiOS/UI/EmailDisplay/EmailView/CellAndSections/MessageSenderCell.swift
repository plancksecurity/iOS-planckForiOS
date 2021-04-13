//
//  MessageSenderCell.swift
//  pEp
//
//  Created by Martín Brude on 11/2/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit

class MessageSenderCell: UITableViewCell {
    @IBOutlet public weak var fromLabel: UILabel!
    @IBOutlet public weak var toContainer: UIView!
    @IBOutlet public weak var containerHeightConstraint: NSLayoutConstraint!
}
