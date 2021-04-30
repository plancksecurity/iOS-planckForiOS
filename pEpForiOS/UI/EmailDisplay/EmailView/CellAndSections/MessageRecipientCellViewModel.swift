//
//  MessageRecipientCellViewModel.swift
//  pEp
//
//  Created by Martín Brude on 26/4/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox

// View Model of the Message Recipient TableViewCell.
class MessageRecipientCellViewModel {

    public var collectionViewViewModel: EmailViewModel.RecipientsCollectionViewViewModel?

    /// Setup the MessageRecipientCellViewModel
    ///
    /// - Parameters:
    ///   - shouldDisplayAllRecipients: Indicates if all the recipients should be shown.
    ///   - containerWidth: The width of the container of the recipients.
    ///   - rowType: The type of the row.
    ///   - recipientCollectionViewCellViewModels: The recipients
    public func setup(shouldDisplayAllRecipients: Bool,
                      containerWidth: CGFloat,
                      rowType: EmailViewModel.EmailRowType,
                      viewModels: [EmailViewModel.CollectionViewCellViewModel],
                      delegate: MessageRecipientCellDelegate) {
        collectionViewViewModel = EmailViewModel.RecipientsCollectionViewViewModel(delegate: delegate,
                                                                                   shouldDisplayAllRecipients: shouldDisplayAllRecipients,
                                                                                   containerWidth: containerWidth,
                                                                                   rowType: rowType,
                                                                                   viewModels: viewModels)
    }
}
