//
//  SubjectTableViewCell.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 18/07/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class SubjectTableViewCell: UITableViewCell {
    @IBOutlet weak var subjectTextField: UITextField!

    override public func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = UITableViewCellSelectionStyle.None
    }
}
