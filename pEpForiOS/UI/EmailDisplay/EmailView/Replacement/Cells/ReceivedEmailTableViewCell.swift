//
//  ReceivedEmailTableViewCell.swift
//  pEp
//
//  Created by Martín Brude on 20/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation


// MARK: Received Email Cell

protocol ReceivedEmailRecipientCellViewModel {
    var title: String { get }
    var value: String { get }
}

protocol ReceivedEmailBodyCellViewModel {
    var attributedText : NSMutableAttributedString { get }
}

class ReceivedEmailRecipientCell : UITableViewCell {
    @IBOutlet weak private var titleLabel: UILabel?
    @IBOutlet weak private var valueLabel: UILabel?

    public func update(with viewModel: ReceivedEmailRecipientCellViewModel) {
        titleLabel?.text = viewModel.title
        valueLabel?.text = viewModel.value
    }
}

class ReceivedEmailBodyCell: UITableViewCell {
    @IBOutlet weak var contentTextView: UITextView!

    public func update(with viewModel: ReceivedEmailBodyCellViewModel) {
        contentTextView.attributedText = viewModel.attributedText
    }
}
