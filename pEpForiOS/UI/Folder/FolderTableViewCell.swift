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
        self.CollapsedArrow.transform.rotated(by: CGFloat(M_PI_2))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
