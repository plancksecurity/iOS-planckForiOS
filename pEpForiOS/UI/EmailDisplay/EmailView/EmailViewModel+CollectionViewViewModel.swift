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

        /// The number collection view items
        public var numberOfCollectionViewCellViewModels: Int {
            return collectionViewCellViewModels?.count ?? 0
        }

        /// The collection view cell view models ('To'/'Cc'/'Bcc' cell, recipient cells and '& X more¡ cell).
        public var collectionViewCellViewModels: [EmailViewModel.CollectionViewCellViewModel]?

        // The recipient type
        private var recipientType: EmailViewModel.RecipientType = .from

        /// The width of the container of the recipients
        public var containerWidth: CGFloat = 0.0

        /// Indicates if all the recipients should be shown.
        /// If false, only the recipients that fit in one line will be shown with, a button to see the rest of them.
        public private(set) var shouldDisplayAllRecipients = false

        /// Delegate to communicate that the button to see more has been pressed
        public weak var delegate : MessageHeaderCellDelegate?

        /// Constructor
        ///
        /// - Parameters:
        ///   - delegate: The delegate to inform when the user pressed the '& X more button'
        ///   - shouldDisplayAllRecipients: Indicates if all the user has to be shown.
        ///   - containerWidth: The width of the container view.
        ///   - recipientType: The recipient type
        ///   - viewModels: The cells view models.
        init(delegate: MessageHeaderCellDelegate,
             shouldDisplayAllRecipients: Bool,
             containerWidth: CGFloat,
             recipientType: EmailViewModel.RecipientType,
             viewModels: [EmailViewModel.CollectionViewCellViewModel]) {
            self.recipientType = recipientType
            self.delegate = delegate
            self.shouldDisplayAllRecipients = shouldDisplayAllRecipients
            self.containerWidth = containerWidth
            setCollectionViewCellViewModels(recipientType, viewModels)
        }

        /// Get the recipient collection view cells to set.
        ///
        /// - Parameters:
        ///   - recipientsCellVMs: The Cell View Model of the recipients.
        ///   - recipientType: The recipient type
        /// - Returns: The recipient collection view cells to set.
        public func recipientCollectionViewCellViewModelToSet(
                         _ recipientsCellVMs: [EmailViewModel.CollectionViewCellViewModel],
                         recipientType: EmailViewModel.RecipientType) -> [EmailViewModel.CollectionViewCellViewModel] {
            var cellsViewModelsToSet = [EmailViewModel.CollectionViewCellViewModel]()

            //Simulate a 'More' button with two digits.
            let and10MoreButtonTitle = NSLocalizedString("& 10 more", comment: "and X more button title - this will only be used to compute a size.")
            var and10MoreCellViewModel: EmailViewModel.CollectionViewCellViewModel?
                = EmailViewModel.CollectionViewCellViewModel(title: and10MoreButtonTitle, recipientType: recipientType)

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
                if (currentOriginX + cellVM.size.width + interItemSpacing) > containerWidth
                    && !shouldDisplayAllRecipients && index > 0 {
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
                let andMoreCellViewModel = EmailViewModel.CollectionViewCellViewModel(title: andMoreButtonTitle,
                                                                                      recipientType: recipientType) {
                    guard let delegate = delegate else {
                        Log.shared.errorAndCrash("Delegate is missing")
                        return
                    }
                    delegate.displayAllRecipients(recipientType: recipientType)
                }
                cellsViewModelsToSet.append(andMoreCellViewModel)
            }
            return cellsViewModelsToSet
        }
    }
}

//MARK:- Private

extension EmailViewModel.RecipientsCollectionViewViewModel {
    private mutating func setCollectionViewCellViewModels(_ recipientType: EmailViewModel.RecipientType,
                                                 _ collectionViewCellViewModels: [EmailViewModel.CollectionViewCellViewModel]) {
        switch recipientType {
        case .from:
            self.collectionViewCellViewModels = collectionViewCellViewModels
        case .to:
            set(collectionViewCellViewModels, recipientType: recipientType)
        case .cc:
            set(collectionViewCellViewModels, recipientType: recipientType)
        case .bcc:
            set(collectionViewCellViewModels, recipientType: recipientType)
        }
    }

    private mutating func set(
                     _ collectionViewCellsVMs: [EmailViewModel.CollectionViewCellViewModel],
        recipientType: EmailViewModel.RecipientType) {
        collectionViewCellViewModels = recipientCollectionViewCellViewModelToSet(collectionViewCellsVMs, recipientType: recipientType)
    }
}
