//
//  FolderTableViewCell.swift
//  pEp
//
//  Created by Martin Brude on 18/06/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

class SubFolderTableViewCell2: UITableViewCell {

    @IBOutlet weak var chevronButton: SectionButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var separatorImageView: UIView!
    @IBOutlet weak var iconLeadingConstraint: NSLayoutConstraint!
    weak var delegate: FolderTableViewCellDelegate?

    var isExpand: Bool = true {
        didSet {
            if isExpand && hasSubfolders {
                chevronButton.imageView?.transform = CGAffineTransform.rotate90Degress()
            } else {
                chevronButton.imageView?.transform = .identity
            }
        }
    }

    var level : Int = 1
    private var padding: CGFloat {
        if Device.isIphone5 {
            return 16.0
        }
        return 25.0
    }

    var hasSubfolders : Bool = false {
        didSet {
            chevronButton.isUserInteractionEnabled = hasSubfolders
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        //Increase tappable area
        chevronButton.contentEdgeInsets = UIEdgeInsets(top: 20, left: 40, bottom: 20, right: 0)
        guard indentationWidth != 0 else { return }
        iconLeadingConstraint.constant = (CGFloat(indentationLevel) * indentationWidth) + padding
        contentView.layoutIfNeeded()
    }

    @IBAction func chevronButtonPressed(_ sender: SectionButton) {
        guard hasSubfolders else { return }
        isExpand = !isExpand
        delegate?.didTapChevronButton(cell: self)
    }
}
