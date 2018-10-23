//
//  AttachmentCell.swift
//  pEp
//
//  Created by Andreas Buff on 27.11.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import SwipeCellKit

//IOS-1369: Old & new are currently using it !! (move to refactor group when done).
class AttachmentCell: SwipeTableViewCell {
    static let reuseId = "AttachmentCell"
    @IBOutlet weak var fileName: UILabel!
    @IBOutlet weak var fileExtension: UILabel!

    var viewModel: AttachmentViewModel?
    //IOS-1369:
    /*{
     didSet {
     viewModel?.delegate = self
     }
     }*/

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
