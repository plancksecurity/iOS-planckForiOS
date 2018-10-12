//
//  RecipientCell.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class RecipientCell: UITableViewCell {
    static let reuseId = "RecipientCell"
    @IBOutlet var recipientTextView: RecipientTextView!
    var viewModel: RecipientCellViewModel?

    public func setup(with viewModel: RecipientCellViewModel) {
        self.viewModel = viewModel
        recipientTextView.viewModel = self.viewModel?.recipientTextViewModel()
        //TODO: recipientTextView initial recipients
    }
}
