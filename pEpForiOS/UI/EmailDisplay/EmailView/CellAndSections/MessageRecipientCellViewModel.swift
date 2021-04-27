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

    /// The collection view cell view models ('To' cell, recipients cell and 1 more cell).
    public var collectionViewCellViewModels: [EmailViewModel.CollectionViewCellViewModel]?

    private var collectionViewViewModel: EmailViewModel.CollectionViewViewModel?

    /// The width of the container of the recipients
    private var containerWidth: CGFloat = 0.0

    /// Indicates if all the recipients should be shown.
    /// If false, only the recipients that fit in one line will be shown with, a button to see the rest of them.
    private var shouldDisplayAllRecipients = false

    // The email row type
    private var rowType: EmailViewModel.EmailRowType = .from

    private func setRecipientCollectionViewCellViewModels(_ rowType: EmailViewModel.EmailRowType,
                                                         _ recipientCollectionViewCellViewModels: [EmailViewModel.CollectionViewCellViewModel]) {
        switch rowType {
        case .from:
            self.collectionViewCellViewModels = recipientCollectionViewCellViewModels
        case .to:
            setToRecipientCollectionViewCellViewModels(recipientCollectionViewCellViewModels)
        case .cc:
            setCCRecipientCollectionViewCellViewModels(recipientCollectionViewCellViewModels)
        case .bcc:
            setBCCRecipientCollectionViewCellViewModels(recipientCollectionViewCellViewModels)
        default:
            Log.shared.errorAndCrash("Email Row type not supported")
        }
    }

    private func setToRecipientCollectionViewCellViewModels(_ recipientsVMs: [EmailViewModel.CollectionViewCellViewModel]) {
        let to = RecipientCellViewModel.FieldType.to.localizedTitle()
        set(to, recipientsVMs, rowType: .to)
    }

    private func setCCRecipientCollectionViewCellViewModels(_ recipientsVMs: [EmailViewModel.CollectionViewCellViewModel]) {
        let cc = RecipientCellViewModel.FieldType.cc.localizedTitle()
        set(cc, recipientsVMs, rowType: .cc)
    }

    private func setBCCRecipientCollectionViewCellViewModels(_ recipientsVMs: [EmailViewModel.CollectionViewCellViewModel]) {
        let bcc = RecipientCellViewModel.FieldType.bcc.localizedTitle()
        set(bcc, recipientsVMs, rowType: .bcc)
    }

    private func set(_ text: String,
                     _ recipientsCellVMs: [EmailViewModel.CollectionViewCellViewModel],
                     rowType: EmailViewModel.EmailRowType) {
        collectionViewCellViewModels
            = collectionViewViewModel?.recipientCollectionViewCellViewModelToSet(text,
                                                                                 recipientsCellVMs,
                                                                                 rowType: rowType,
                                                                                 containerWidth: containerWidth,
                                                                                 shouldDisplayAllRecipients: shouldDisplayAllRecipients)
    }
}

//MARK:- Setup

extension MessageRecipientCellViewModel {

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
                      recipientCollectionViewCellViewModels: [EmailViewModel.CollectionViewCellViewModel],
                      delegate: MessageRecipientCellDelegate) {
        self.shouldDisplayAllRecipients = shouldDisplayAllRecipients
        self.containerWidth = containerWidth
        self.rowType = rowType
        self.collectionViewViewModel = EmailViewModel.CollectionViewViewModel(delegate: delegate)
        setRecipientCollectionViewCellViewModels(rowType, recipientCollectionViewCellViewModels)
    }
}
