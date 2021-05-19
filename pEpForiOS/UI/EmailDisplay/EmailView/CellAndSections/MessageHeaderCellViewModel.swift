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

    private var profilePictureComposer: ProfilePictureComposerProtocol
    private var displayedImageIdentity: Identity

    /// From CollectionView VM
    public var fromCollectionViewViewModel: EmailViewModel.RecipientsCollectionViewViewModel?
    /// Tos CollectionView VM
    public var tosCollectionViewViewModel: EmailViewModel.RecipientsCollectionViewViewModel?
    /// CCs CollectionView VM
    public var ccsCollectionViewViewModel: EmailViewModel.RecipientsCollectionViewViewModel?
    /// BBC CollectionView VM
    public var bccsCollectionViewViewModel: EmailViewModel.RecipientsCollectionViewViewModel?

    private let queueForHeavyStuff: OperationQueue = {
        let createe = OperationQueue()
        createe.qualityOfService = .userInitiated
        createe.name = "security.pep.MessageHeaderCellViewModel.queueForHeavyStuff"
        return createe
    }()

    /// Constructor
    ///
    /// - Parameters:
    ///   - profilePictureComposer: The profile picture composer. Optional.
    ///   - displayedImageIdentity: The identity to obtain the image.
    init(profilePictureComposer: ProfilePictureComposerProtocol = PepProfilePictureComposer(),
         displayedImageIdentity: Identity) {
        self.displayedImageIdentity = displayedImageIdentity
        self.profilePictureComposer = profilePictureComposer
    }

    /// Setup the MessageRecipientCellViewModel
    ///
    /// - Parameters:
    ///   - shouldDisplayAllRecipients: Indicates if all the recipients should be shown.
    ///   - containerWidth: The width of the container of the recipients.
    ///   - rowType: The type of the row.
    ///   - recipientCollectionViewCellViewModels: The recipients
    public func setup(shouldDisplayAll: [EmailViewModel.RecipientType: Bool],
                      containerWidth: CGFloat,
                      rowType: EmailViewModel.EmailRowType,
                      fromViewModel: EmailViewModel.CollectionViewCellViewModel,
                      toViewModels: [EmailViewModel.CollectionViewCellViewModel],
                      ccViewModels: [EmailViewModel.CollectionViewCellViewModel],
                      bccViewModels: [EmailViewModel.CollectionViewCellViewModel],
                      delegate: MessageHeaderCellDelegate) {


        // From is never collapsed (it's always one). 
        fromCollectionViewViewModel = EmailViewModel.RecipientsCollectionViewViewModel(delegate: delegate,
                                                                                       shouldDisplayAllRecipients: true,
                                                                                       containerWidth: containerWidth,
                                                                                       recipientType: .from,
                                                                                       viewModels: [fromViewModel])

        tosCollectionViewViewModel = EmailViewModel.RecipientsCollectionViewViewModel(delegate: delegate,
                                                                                      shouldDisplayAllRecipients: shouldDisplayAll[.to] ?? false,
                                                                                      containerWidth: containerWidth,
                                                                                      recipientType: .to,
                                                                                      viewModels: toViewModels)

        ccsCollectionViewViewModel = EmailViewModel.RecipientsCollectionViewViewModel(delegate: delegate,
                                                                                      shouldDisplayAllRecipients: shouldDisplayAll[.cc] ?? false,
                                                                                      containerWidth: containerWidth,
                                                                                      recipientType: .cc,
                                                                                      viewModels: ccViewModels)

        bccsCollectionViewViewModel = EmailViewModel.RecipientsCollectionViewViewModel(delegate: delegate,
                                                                                      shouldDisplayAllRecipients: shouldDisplayAll[.bcc] ?? false,
                                                                                      containerWidth: containerWidth,
                                                                                      recipientType: .bcc,
                                                                                      viewModels: bccViewModels)

    }

    public func getProfilePicture(completion: @escaping (UIImage?) -> ()) {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                // Valid case. We might have been dismissed already.
                // Do nothing ...
                return
            }
            let operation = me.getProfilePictureOperation(completion: completion)
            me.queueForHeavyStuff.addOperation(operation)
        }
    }

    private func getProfilePictureOperation(completion: @escaping (UIImage?) -> ())
    -> SelfReferencingOperation {
        let identitykey = IdentityImageTool.IdentityKey(identity: displayedImageIdentity)
        let profilePictureOperation = SelfReferencingOperation { [weak self] operation in
            guard let me = self else {
                return
            }
            guard
                let operation = operation,
                !operation.isCancelled else {
                return
            }
            let profileImage = me.profilePictureComposer.profilePicture(for: identitykey)
            DispatchQueue.main.async {
                completion(profileImage)
            }
        }
        return profilePictureOperation
    }

    public func unsubscribeForUpdates() {
        queueForHeavyStuff.cancelAllOperations()
    }
}
