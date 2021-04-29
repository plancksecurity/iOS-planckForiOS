//
//  EmailViewController+CollectionViewViewModel.swift
//  pEp
//
//  Created by Martín Brude on 27/4/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox

extension EmailViewModel {

    struct RecipientsCollectionViewViewModel {

        /// The collection view cell view models ('To' cell, recipients cell and 1 more cell).
        public var collectionViewCellViewModels: [EmailViewModel.CollectionViewCellViewModel]?

        // The email row type
        private var rowType: EmailViewModel.EmailRowType = .from

        /// The width of the container of the recipients
        public var containerWidth: CGFloat = 0.0

        /// Indicates if all the recipients should be shown.
        /// If false, only the recipients that fit in one line will be shown with, a button to see the rest of them.
        public private(set) var shouldDisplayAllRecipients = false

        /// Delegate to communicate that the button to see more has been pressed
        public weak var delegate : MessageRecipientCellDelegate?

        /// Constructor
        ///
        /// - Parameters:
        ///   - delegate: The delegate to inform when the user pressed the '& X more button'
        ///   - shouldDisplayAllRecipients: Indicates if all the user has to be shown.
        ///   - containerWidth: The width of the container view.
        ///   - rowType: The type of the row.
        ///   - viewModels: The cells view models.
        init(delegate: MessageRecipientCellDelegate, shouldDisplayAllRecipients: Bool, containerWidth: CGFloat,
             rowType: EmailViewModel.EmailRowType, viewModels: [EmailViewModel.CollectionViewCellViewModel]) {
            self.rowType = rowType
            self.delegate = delegate
            self.shouldDisplayAllRecipients = shouldDisplayAllRecipients
            self.containerWidth = containerWidth
            setCollectionViewCellViewModels(rowType, viewModels)
        }

        /// Get the recipient collection view cells to set.
        /// - Parameters:
        ///   - text: The text of the EmailViewRowType ("To:", "CC:", "BCC:", for example).
        ///   - recipientsCellVMs: The Cell View Model of the recipients.
        ///   - rowType: The email row type.
        ///   - containerWidth: The width of the container
        ///
        /// - Returns:The recipient collection view cells to set.
        public func recipientCollectionViewCellViewModelToSet(_ text: String,
                         _ recipientsCellVMs: [EmailViewModel.CollectionViewCellViewModel],
                         rowType: EmailViewModel.EmailRowType) -> [EmailViewModel.CollectionViewCellViewModel] {
            //'To' button, for example.
            let recipientTypeCellViewModel = EmailViewModel.CollectionViewCellViewModel(title: text, rowType: rowType)
            var cellsViewModelsToSet = [recipientTypeCellViewModel]

            //Simulate a 'More' button with two digits.
            let and10MoreButtonTitle = NSLocalizedString("& 10 more", comment: "and X more button title - this will only be used to compute a size.")
            var and10MoreCellViewModel: EmailViewModel.CollectionViewCellViewModel?
                = EmailViewModel.CollectionViewCellViewModel(title: and10MoreButtonTitle, rowType: rowType)

            //Check if buttons will exceed 1 line
            var currentOriginX: CGFloat = 0

            var surplusCellsVM = [EmailViewModel.CollectionViewCellViewModel]()
            var recipientCellsToSet = [EmailViewModel.CollectionViewCellViewModel]()

            let interItemSpacing: CGFloat = 2.0

            //Recipients
            for (index, cellVM) in recipientsCellVMs.enumerated() {
                // Would the next cell exceed the container width?
                // If so, separate the surplus.

                //Evaluate if the width of the cells exceeds the container width.
                if (currentOriginX + cellVM.size.width + interItemSpacing) > containerWidth && !shouldDisplayAllRecipients {
                    // The next items would exceed the line.
                    let surplus = recipientsCellVMs[index..<recipientsCellVMs.count]
                    surplusCellsVM.append(contentsOf: surplus)
                    currentOriginX += and10MoreCellViewModel?.size.width ?? 0.0
                    and10MoreCellViewModel = nil
                    break
                } else {
                    currentOriginX += cellVM.size.width + interItemSpacing
                    recipientCellsToSet.append(cellVM)
                }
            }
            cellsViewModelsToSet.append(contentsOf: recipientCellsToSet)

            //'& X more' button.
            if !surplusCellsVM.isEmpty {
                let format = NSLocalizedString("& %1$@ more", comment: "Indicate there are more recipients that will be shown when the user taps this button.")
                let andMoreButtonTitle = String.localizedStringWithFormat(format, "\(surplusCellsVM.count)")
                let andMoreCellViewModel = EmailViewModel.CollectionViewCellViewModel(title: andMoreButtonTitle, rowType: rowType) {
                    guard let delegate = delegate else {
                        Log.shared.errorAndCrash("Delegate is missing")
                        return
                    }
                    delegate.displayAllRecipients(rowType: rowType)
                }
                cellsViewModelsToSet.append(andMoreCellViewModel)
            }
            return cellsViewModelsToSet
        }
    }
}

//MARK:- Private

extension EmailViewModel.RecipientsCollectionViewViewModel {
    private mutating func setCollectionViewCellViewModels(_ rowType: EmailViewModel.EmailRowType,
                                                 _ collectionViewCellViewModels: [EmailViewModel.CollectionViewCellViewModel]) {
        switch rowType {
        case .from:
            self.collectionViewCellViewModels = collectionViewCellViewModels
        case .to:
            set(RecipientCellViewModel.FieldType.to.localizedTitle(), collectionViewCellViewModels, rowType: rowType)
        case .cc:
            set(RecipientCellViewModel.FieldType.cc.localizedTitle(), collectionViewCellViewModels, rowType: rowType)
        case .bcc:
            set(RecipientCellViewModel.FieldType.bcc.localizedTitle(), collectionViewCellViewModels, rowType: rowType)

        default:
            Log.shared.errorAndCrash("Email Row type not supported")
        }
    }

    private mutating func set(_ text: String,
                     _ collectionViewCellsVMs: [EmailViewModel.CollectionViewCellViewModel],
                     rowType: EmailViewModel.EmailRowType) {
        collectionViewCellViewModels = recipientCollectionViewCellViewModelToSet(text, collectionViewCellsVMs, rowType: rowType)
    }
}
