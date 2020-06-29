//
//  FolderTableViewCell.swift
//  pEp
//
//  Created by Martin Brude on 18/06/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

protocol FolderTableViewCellDelegate: class {
    func didTapChevronButton(cell:  UITableViewCell)
}

class FolderTableViewCell: UITableViewCell {

    private var isShown = true
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var chevronButton: UIButton!

    weak var delegate: FolderTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        chevronButton.imageView?.transform = CGAffineTransform.rotate90Degress()
    }

    /// Rotates the button and notify the view controller
    /// - Parameter sender: The button pressed
    @IBAction func chevronButtonTapped(_ sender: UIButton) {
        if isShown {
            sender.imageView?.transform = .identity
            isShown = false
        } else {
            sender.imageView?.transform = CGAffineTransform.rotate90Degress()
            isShown = true
        }
        delegate?.didTapChevronButton(cell: self)
    }
}
