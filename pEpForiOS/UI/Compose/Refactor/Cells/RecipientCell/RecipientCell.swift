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
    @IBOutlet weak var title: UILabel!
    @IBOutlet var recipientTextView: RecipientTextView!
    var viewModel: RecipientCellViewModel?

    public func setup(with viewModel: RecipientCellViewModel) {
        self.viewModel = viewModel
        recipientTextView.viewModel = self.viewModel?.recipientTextViewModel()
        title.text = viewModel.type.localizedTitle()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        recipientTextView.text = ""
    }
}
