//
//  MessageSenderAndRecipientsCell.swift
//  pEp
//
//  Created by Martín Brude on 11/2/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit

//TODO: rm this.
class MessageSenderAndRecipientsCell: UITableViewCell {
    // Will be calculated on runtime
    private var recipientButtonHeight: CGFloat = 0
    // Fixed distance between recipient buttons
    private let recipientButtonSpacingX: CGFloat = 4

    @IBOutlet private weak var fromButton: RecipientButton!
    @IBOutlet private weak var toContainer: UIView!
    @IBOutlet private weak var containerHeightConstraint: NSLayoutConstraint!

    public func setup(fromVM: EmailViewModel.RecipientCollectionViewCellViewModel,
                      tosVM: [EmailViewModel.RecipientCollectionViewCellViewModel]) {
        func display(_ buttons: [RecipientButton]) {
            let containerWidth = toContainer.frame.size.width
            var currentOriginX: CGFloat = 0
            var currentOriginY: CGFloat = 0

            buttons.forEach { button in
                // if current origin X + label width is be greater than the container view width
                // move the label to next row
                if currentOriginX + button.frame.width > containerWidth {
                    currentOriginX = 0
                    currentOriginY += recipientButtonHeight
                }

                // set the frame origin
                button.frame.origin.x = currentOriginX
                button.frame.origin.y = currentOriginY

                // increment current X by btn width + spacing
                currentOriginX += button.frame.width + recipientButtonSpacingX
            }
            // update container view height
            containerHeightConstraint.constant = currentOriginY + recipientButtonHeight
        }
        if #available(iOS 13.0, *) {
            if let action = fromVM.action {
                fromButton.setup(text: fromVM.title, color: .label, action: action)
            }

        } else {
            if let action = fromVM.action {
                fromButton.setup(text: fromVM.title, color: .black, action: action)
            }
        }
        toContainer.subviews.forEach({$0.removeFromSuperview()})
        let toText = NSLocalizedString("To:", comment: "To: - To label")
        var buttons = [RecipientButton]()
        /// First, add 'To:' button
        let toButton = RecipientButton.with(text: toText)
        // 'To:' shouldn't be tappable.
        toButton.isUserInteractionEnabled = false
        buttons.append(toButton)

        /// Then add the Recipient Buttons
        tosVM.forEach { (to) in
            let recipientButton = RecipientButton.with(text: to.title, action: to.action)
            recipientButtonHeight = recipientButton.frame.height
            recipientButton.frame.size.width = recipientButton.intrinsicContentSize.width
            recipientButton.frame.size.height = recipientButtonHeight
            buttons.append(recipientButton)
        }
        buttons.forEach { (button) in
            toContainer.addSubview(button)
        }
        display(buttons)
    }
}

