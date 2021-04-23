//
//  RecipientCollectionViewCell.swift
//  pEp
//
//  Created by Martín Brude on 21/4/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox

class RecipientCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var recipientButton: RecipientButton!
    public static let cellId = "recipientCellId"

    func setup(cellVM: EmailViewModel.RecipientCollectionViewCellViewModel) {
        var color: UIColor = .darkText
        switch cellVM.rowType {
        case .to2, .cc2, .bcc2:
            if #available(iOS 13.0, *) {
                color = .secondaryLabel
            } else {
                color = .lightGray
            }
        case .from2:
            if #available(iOS 13.0, *) {
                color = .label
            } else {
                color = .darkText
            }
        default:
            Log.shared.errorAndCrash("Row type not supported")
        }
        recipientButton.setup(text: cellVM.title, color: color, action: cellVM.action)
    }
}
