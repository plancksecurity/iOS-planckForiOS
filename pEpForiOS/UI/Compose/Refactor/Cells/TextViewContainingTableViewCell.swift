//
//  TextViewContainingTableViewCell.swift
//  pEp
//
//  Created by Andreas Buff on 08.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

protocol TextViewContainingTableViewCellProtocol {
    var textView: UITextView! { get set }
}

class TextViewContainingTableViewCell: UITableViewCell, TextViewContainingTableViewCellProtocol {

    @IBOutlet weak public var textView: UITextView!
}
