//
//  FolderTableViewCell.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 21/02/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

class FolderTableViewCell: UITableViewCell {

    @IBOutlet weak var Icon: UIImageView!

    @IBOutlet weak var labelName: UILabel!

    @IBOutlet weak var labelUnreadNumber: UILabel!

    @IBOutlet weak var CollapsedArrow: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configure(viewModel: FolderCellViewModel) {
        self.Icon.image = viewModel.icon
        self.labelName.text = viewModel.title
        self.labelUnreadNumber.text = "\(viewModel.number)"
        self.CollapsedArrow.image = viewModel.arrow
        self.CollapsedArrow.transform = self.CollapsedArrow.transform.rotated(
            by: CGFloat(Double.pi / 4))
        self.indentationLevel = viewModel.level
        self.indentationWidth = CGFloat(10.0)
        self.shouldIndentWhileEditing = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.layoutMargins.left = CGFloat(self.indentationLevel) * self.indentationWidth + self.contentView.layoutMargins.left
        //self.contentView.layoutIfNeeded()
        self.contentView.layoutSubviews()
    }
}
