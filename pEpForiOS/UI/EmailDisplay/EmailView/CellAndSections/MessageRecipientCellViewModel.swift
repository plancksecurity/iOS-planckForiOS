//
//  MessageRecipientCellViewModel.swift
//  pEp
//
//  Created by Martín Brude on 26/4/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

protocol MessageHeaderCellDelegate: AnyObject {
    func displayAllRecipients(recipientType: EmailViewModel.RecipientType)
}

// View Model of the Message Recipient TableViewCell.
class MessageRecipientCellViewModel {

    public var collectionViewViewModel: EmailViewModel.RecipientsCollectionViewViewModel?

    /// Setup the MessageRecipientCellViewModel
    ///
    /// - Parameters:
    ///   - shouldDisplayAllRecipients: Indicates if all the recipients should be shown.
    ///   - containerWidth: The width of the container of the recipients.
    ///   - recipientType: The recipient type.
    ///   - recipientCollectionViewCellViewModels: The recipients
    public func setup(shouldDisplayAllRecipients: Bool,
                      containerWidth: CGFloat,
                      recipientType: EmailViewModel.RecipientType,
                      viewModels: [EmailViewModel.CollectionViewCellViewModel],
                      delegate: MessageHeaderCellDelegate) {
        collectionViewViewModel = EmailViewModel.RecipientsCollectionViewViewModel(delegate: delegate,
                                                                                   shouldDisplayAllRecipients: shouldDisplayAllRecipients,
                                                                                   containerWidth: containerWidth,
                                                                                   recipientType: recipientType,
                                                                                   viewModels: viewModels)
    }
}
