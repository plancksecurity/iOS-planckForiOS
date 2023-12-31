//
//  AttachmentCell.swift
//  pEp
//
//  Created by Andreas Buff on 27.11.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import SwipeCellKit

class AttachmentCell: SwipeTableViewCell {
    static let reuseId = "AttachmentCell"
    @IBOutlet weak var fileName: UILabel!
    @IBOutlet weak var fileExtension: UILabel!

    var viewModel: AttachmentViewModel?

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }

    public func setup(with viewModel: AttachmentViewModel) {
        self.viewModel = viewModel
        fileName.text = viewModel.fileName
        fileExtension.text = viewModel.fileExtension
    }

    override func prepareForReuse() {
        fileName.text = ""
        fileExtension.text = ""
    }
}
