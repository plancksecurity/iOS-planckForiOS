//
//  MessageRecipientCellViewModel.swift
//  pEp
//
//  Created by Martín Brude on 26/4/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox

class MessageRecipientCellViewModel {

    /// The width of the container of the recipients
    private var containerWidth: CGFloat = 0.0

    /// Indicates if all the recipients should be shown.
    /// If false, only the recipients that fit in one line will be shown with, a button to see the rest of them.
    private var shouldDisplayAll = false

    /// Delegate to communicate that the button to see more has been pressed
    public weak var delegate : MessageRecipientCellDelegate?

    /// The collection view cell view models ('To' cell, recipients cell and 1 more cell).
    public var recipientCollectionViewCellViewModels: [EmailViewModel.RecipientCollectionViewCellViewModel]?

    // The email row type
    private var rowType : EmailViewModel.EmailRowType = .from

    /// Get the recipient collection view cells to set.
    /// - Parameters:
    ///   - text: The text of the EmailViewRowType ("To:", "CC:", "BCC:", for example).
    ///   - recipientsCellVMs: The Cell View Model of the recipients.
    ///   - rowType: The email row type.
    ///   - containerWidth: The width of the container
    ///
    /// - Returns:The recipient collection view cells to set.
    public func recipientCollectionViewCellViewModelToSet(_ text: String,
                     _ recipientsCellVMs: [EmailViewModel.RecipientCollectionViewCellViewModel],
                     rowType: EmailViewModel.EmailRowType,
                     containerWidth: CGFloat) -> [EmailViewModel.RecipientCollectionViewCellViewModel] {
        //'To' button, for example.
        let recipientTypeCellViewModel = EmailViewModel.RecipientCollectionViewCellViewModel(title: text, rowType: rowType)
        var cellsViewModelsToSet = [recipientTypeCellViewModel]


        let and10MoreButtonTitle = NSLocalizedString("& 10 more", comment: "and X more button title")
        let and10MoreCellViewModel = EmailViewModel.RecipientCollectionViewCellViewModel(title: and10MoreButtonTitle, rowType: rowType)


        //Check if buttons will exceed 1 line
        var currentOriginX: CGFloat = 0

        var surplusCellsVM = [EmailViewModel.RecipientCollectionViewCellViewModel]()
        var recipientCellsToSet = [EmailViewModel.RecipientCollectionViewCellViewModel]()

        let interItemSpacing: CGFloat = 2.0

        //Recipients
        for (index, cellVM) in recipientsCellVMs.enumerated() {
            let minInterItemSpacing: CGFloat = CGFloat(index) * interItemSpacing
            // Would the next cell exceed the container width?
            // If so, separate the surplus.
            if (currentOriginX + cellVM.size.width + and10MoreCellViewModel.size.width + minInterItemSpacing) > containerWidth && !shouldDisplayAll {
                // The next items would exceed the line.
                let surplus = recipientsCellVMs[index..<recipientsCellVMs.count]
                surplusCellsVM.append(contentsOf: surplus)
                break
            } else {
                currentOriginX += cellVM.size.width
                recipientCellsToSet.append(cellVM)
            }
        }
        cellsViewModelsToSet.append(contentsOf: recipientCellsToSet)

        //'& X more' button.
        if !surplusCellsVM.isEmpty {
            let andMoreButtonTitle = NSLocalizedString("& \(surplusCellsVM.count) more", comment: "and X more button title")
            let andMoreCellViewModel = EmailViewModel.RecipientCollectionViewCellViewModel(title: andMoreButtonTitle, rowType: rowType) { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }
                me.delegate?.displayAllRecipients(rowType: rowType)
            }
            cellsViewModelsToSet.append(andMoreCellViewModel)
        }
        return cellsViewModelsToSet
    }

    private func setRecipientCollectionViewCellViewModels(_ rowType: EmailViewModel.EmailRowType,
                                                         _ recipientCollectionViewCellViewModels: [EmailViewModel.RecipientCollectionViewCellViewModel]) {
        switch rowType {
        case .from:
            self.recipientCollectionViewCellViewModels = recipientCollectionViewCellViewModels
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

    private func setToRecipientCollectionViewCellViewModels(_ recipientsVMs: [EmailViewModel.RecipientCollectionViewCellViewModel]) {
        let to = RecipientCellViewModel.FieldType.to.localizedTitle()
        set(to, recipientsVMs, rowType: .to)
    }

    private func setCCRecipientCollectionViewCellViewModels(_ recipientsVMs: [EmailViewModel.RecipientCollectionViewCellViewModel]) {
        let cc = RecipientCellViewModel.FieldType.cc.localizedTitle()
        set(cc, recipientsVMs, rowType: .cc)
    }

    private func setBCCRecipientCollectionViewCellViewModels(_ recipientsVMs: [EmailViewModel.RecipientCollectionViewCellViewModel]) {
        let bcc = RecipientCellViewModel.FieldType.bcc.localizedTitle()
        set(bcc, recipientsVMs, rowType: .bcc)
    }

    private func set(_ text: String,
                     _ recipientsCellVMs: [EmailViewModel.RecipientCollectionViewCellViewModel],
                     rowType: EmailViewModel.EmailRowType) {
        recipientCollectionViewCellViewModels = recipientCollectionViewCellViewModelToSet(text,
                                                                                          recipientsCellVMs,
                                                                                          rowType: rowType,
                                                                                          containerWidth: containerWidth)
    }
}

//MARK:- Setup

extension MessageRecipientCellViewModel {

    /// Setup the MessageRecipientCellViewModel
    ///
    /// - Parameters:
    ///   - shouldDisplayAll: Indicates if all the recipients should be shown.
    ///   - containerWidth: The width of the container of the recipients.
    ///   - rowType: The type of the row.
    ///   - recipientCollectionViewCellViewModels: The recipients
    public func setup(shouldDisplayAll: Bool,
                      containerWidth: CGFloat,
                      rowType: EmailViewModel.EmailRowType,
                      recipientCollectionViewCellViewModels: [EmailViewModel.RecipientCollectionViewCellViewModel]) {
        self.shouldDisplayAll = shouldDisplayAll
        self.containerWidth = containerWidth
        self.rowType = rowType
        setRecipientCollectionViewCellViewModels(rowType, recipientCollectionViewCellViewModels)
    }
}
