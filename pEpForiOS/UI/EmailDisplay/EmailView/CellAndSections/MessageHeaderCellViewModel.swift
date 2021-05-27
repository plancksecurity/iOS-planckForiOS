//
//  MessageHeaderCellViewModel.swift
//  pEp
//
//  Created by Martín Brude on 17/5/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit
import Foundation
import MessageModel
import pEpIOSToolbox

class MessageHeaderCellViewModel {

    private var displayedImageIdentity: Identity

    /// From CollectionView VM
    public var fromCollectionViewViewModel: EmailViewModel.RecipientsCollectionViewViewModel?
    /// Tos CollectionView VM
    public var tosCollectionViewViewModel: EmailViewModel.RecipientsCollectionViewViewModel?
    /// CCs CollectionView VM
    public var ccsCollectionViewViewModel: EmailViewModel.RecipientsCollectionViewViewModel?
    /// BBC CollectionView VM
    public var bccsCollectionViewViewModel: EmailViewModel.RecipientsCollectionViewViewModel?

    private let identityImageTool = IdentityImageTool()
    /// Constructor
    ///
    /// - Parameters:
    ///   - displayedImageIdentity: The identity to obtain the image.
    init(displayedImageIdentity: Identity) {
        self.displayedImageIdentity = displayedImageIdentity
    }

    /// Setup the MessageRecipientCellViewModel
    ///
    /// - Parameters:
    ///   - shouldDisplayAllRecipients: Indicates if all the recipients should be shown.
    ///   - containerWidth: The width of the container of the recipients.
    ///   - rowType: The type of the row.
    ///   - recipientCollectionViewCellViewModels: The recipients
    public func setup(shouldDisplayAll: [EmailViewModel.RecipientType: Bool],
                      recipientsContainerWidth: CGFloat,
                      fromContainerWidth: CGFloat,
                      fromViewModel: EmailViewModel.CollectionViewCellViewModel,
                      toViewModels: [EmailViewModel.CollectionViewCellViewModel],
                      ccViewModels: [EmailViewModel.CollectionViewCellViewModel],
                      bccViewModels: [EmailViewModel.CollectionViewCellViewModel],
                      delegate: MessageHeaderCellDelegate) {


        // From is never collapsed (it's always one). 
        fromCollectionViewViewModel = EmailViewModel.RecipientsCollectionViewViewModel(delegate: delegate,
                                                                                       shouldDisplayAllRecipients: true,
                                                                                       containerWidth: fromContainerWidth,
                                                                                       recipientType: .from,
                                                                                       viewModels: [fromViewModel])

        tosCollectionViewViewModel = EmailViewModel.RecipientsCollectionViewViewModel(delegate: delegate,
                                                                                      shouldDisplayAllRecipients: shouldDisplayAll[.to] ?? false,
                                                                                      containerWidth: recipientsContainerWidth,
                                                                                      recipientType: .to,
                                                                                      viewModels: toViewModels)

        ccsCollectionViewViewModel = EmailViewModel.RecipientsCollectionViewViewModel(delegate: delegate,
                                                                                      shouldDisplayAllRecipients: shouldDisplayAll[.cc] ?? false,
                                                                                      containerWidth: recipientsContainerWidth,
                                                                                      recipientType: .cc,
                                                                                      viewModels: ccViewModels)

        bccsCollectionViewViewModel = EmailViewModel.RecipientsCollectionViewViewModel(delegate: delegate,
                                                                                      shouldDisplayAllRecipients: shouldDisplayAll[.bcc] ?? false,
                                                                                      containerWidth: recipientsContainerWidth,
                                                                                      recipientType: .bcc,
                                                                                      viewModels: bccViewModels)
    }

    /// Get the profile picture that belongs to the identity who sent the email.
    ///
    /// - Parameter completion: Completion callback that is executed when the operation fininshes.
    /// - Returns: The profile picture.
    public func getProfilePicture(completion: @escaping (UIImage?) -> ()) {
        identityImageTool.getProfilePicture(identity: displayedImageIdentity, completion: completion)
    }

    /// - Parameter type: The recipient type
    /// - Returns: The number of CollectionViewCell VMs for recipient type passed.
    public func numberOfCVVM(for type: EmailViewModel.RecipientType) -> Int {
        switch type {
        case .from:
            guard let numberOfFrom = fromCollectionViewViewModel?.numberOfCollectionViewCellViewModels, numberOfFrom == 1 else {
                Log.shared.errorAndCrash("There should be only 1 From recipient")
                return 0
            }
            return numberOfFrom
        case .to:
            guard let numberOfTos = tosCollectionViewViewModel?.numberOfCollectionViewCellViewModels, numberOfTos > 0 else {
                Log.shared.errorAndCrash("There should be at least 1 To recipient")
                return 0
            }
            return numberOfTos
        case .cc:
            return ccsCollectionViewViewModel?.numberOfCollectionViewCellViewModels ?? 0
        case .bcc:
            return bccsCollectionViewViewModel?.numberOfCollectionViewCellViewModels ?? 0
        }
    }

    /// - Parameter type: The recipient type.
    /// - Returns: The CollectionView VM for recipient type passed.
    public func recipientsCVVM(for type: EmailViewModel.RecipientType) -> EmailViewModel.RecipientsCollectionViewViewModel? {
        switch type {
        case .from:
            return fromCollectionViewViewModel
        case .to:
            return tosCollectionViewViewModel
        case .cc:
            return ccsCollectionViewViewModel
        case .bcc:
            return bccsCollectionViewViewModel
        }
    }
}
