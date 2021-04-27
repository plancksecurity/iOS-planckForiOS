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

    // The email row type
    private var rowType: EmailViewModel.EmailRowType = .from

    private func setCollectionViewCellViewModels(_ rowType: EmailViewModel.EmailRowType,
                                                 _ collectionViewCellViewModels: [EmailViewModel.CollectionViewCellViewModel]) {
        switch rowType {
        case .from:
            self.collectionViewCellViewModels = collectionViewCellViewModels
        case .to:
            setToRecipientCollectionViewCellViewModels(collectionViewCellViewModels)
        case .cc:
            setCCRecipientCollectionViewCellViewModels(collectionViewCellViewModels)
        case .bcc:
            setBCCRecipientCollectionViewCellViewModels(collectionViewCellViewModels)
        default:
            Log.shared.errorAndCrash("Email Row type not supported")
        }
    }

    private func setToRecipientCollectionViewCellViewModels(_ collectionViewCellsVMs: [EmailViewModel.CollectionViewCellViewModel]) {
        let to = RecipientCellViewModel.FieldType.to.localizedTitle()
        set(to, collectionViewCellsVMs, rowType: .to)
    }

    private func setCCRecipientCollectionViewCellViewModels(_ collectionViewCellsVMs: [EmailViewModel.CollectionViewCellViewModel]) {
        let cc = RecipientCellViewModel.FieldType.cc.localizedTitle()
        set(cc, collectionViewCellsVMs, rowType: .cc)
    }

    private func setBCCRecipientCollectionViewCellViewModels(_ collectionViewCellsVMs: [EmailViewModel.CollectionViewCellViewModel]) {
        let bcc = RecipientCellViewModel.FieldType.bcc.localizedTitle()
        set(bcc, collectionViewCellsVMs, rowType: .bcc)
    }

    private func set(_ text: String,
                     _ collectionViewCellsVMs: [EmailViewModel.CollectionViewCellViewModel],
                     rowType: EmailViewModel.EmailRowType) {
        collectionViewCellViewModels = collectionViewViewModel?.recipientCollectionViewCellViewModelToSet(text, collectionViewCellsVMs, rowType: rowType)
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
        self.rowType = rowType
        self.collectionViewViewModel = EmailViewModel.CollectionViewViewModel(delegate: delegate)
        self.collectionViewViewModel?.shouldDisplayAllRecipients = shouldDisplayAllRecipients
        self.collectionViewViewModel?.containerWidth = containerWidth
        setCollectionViewCellViewModels(rowType, recipientCollectionViewCellViewModels)
    }
}
