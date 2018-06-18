//
//  FullMessageCell.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 14/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class FullMessageCell: UITableViewCell, MessageViewModelConfigurable {

    @IBOutlet weak var roundedView: UIView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var bodyText: UITextView!

    func configure(for viewModel:MessageViewModel) {
        addressLabel.text = viewModel.from
        subjectLabel.text = viewModel.subject
        bodyText.attributedText = viewModel.body
        bodyText.tintColor = UIColor.pEpGreen
        backgroundColor = UIColor.clear
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
    }

}
