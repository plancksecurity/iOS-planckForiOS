//
//  FolderTableViewCell.swift
//  pEp
//
//  Created by Martin Brude on 18/06/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

protocol FolderTableViewCellDelegate: class {
    func didTapChevronButton(cell:  UITableViewCell)
}

class FolderTableViewCell: UITableViewCell {

    /// Every indentation level will move the cell this distance to the right.
    private let subFolderIndentationWidth: CGFloat = 25.0

    @IBOutlet weak var unreadMailsLabel: UILabel!
    @IBOutlet weak var chevronButton: SectionButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var separatorImageView: UIView!
    @IBOutlet weak var iconLeadingConstraint: NSLayoutConstraint!
    weak var delegate: FolderTableViewCellDelegate?

    var shouldRotateChevron: Bool = true {
        didSet {
            chevronButton.imageView?.transform = shouldRotateChevron ? CGAffineTransform.rotate90Degress() : .identity
        }
    }

    var level : Int = 1
    var padding: CGFloat = 0

    override func layoutSubviews() {
        //Increase tappable area
        chevronButton.contentEdgeInsets = UIEdgeInsets(top: 20, left: 40, bottom: 20, right: 0)
        iconLeadingConstraint.constant = (CGFloat(indentationLevel) * subFolderIndentationWidth) + padding
        super.layoutSubviews()
    }

    @IBAction func chevronButtonPressed(_ sender: SectionButton) {
        shouldRotateChevron = !shouldRotateChevron
        delegate?.didTapChevronButton(cell: self)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        indentationLevel = 0
        titleLabel.text = ""
        unreadMailsLabel.text = ""
        iconImageView.image = nil
        chevronButton.isUserInteractionEnabled = false
        titleLabel?.textColor = .black
        separatorImageView.isHidden = true
        iconLeadingConstraint.constant = 16
    }
}
