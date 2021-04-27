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

    struct RecipientCollectionViewViewModel {

        /// Delegate to communicate that the button to see more has been pressed
        public weak var delegate : MessageRecipientCellDelegate?

        init(delegate: MessageRecipientCellDelegate) {
            self.delegate = delegate
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
                         _ recipientsCellVMs: [EmailViewModel.RecipientCollectionViewCellViewModel],
                         rowType: EmailViewModel.EmailRowType,
                         containerWidth: CGFloat,
                         shouldDisplayAllRecipients: Bool) -> [EmailViewModel.RecipientCollectionViewCellViewModel] {
            //'To' button, for example.
            let recipientTypeCellViewModel = EmailViewModel.RecipientCollectionViewCellViewModel(title: text, rowType: rowType)
            var cellsViewModelsToSet = [recipientTypeCellViewModel]

            //Simulate a 'More' button with two digits.
            let and10MoreButtonTitle = NSLocalizedString("& 10 more", comment: "and X more button title - this will only be used to compute a size.")
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
                if (currentOriginX + cellVM.size.width + and10MoreCellViewModel.size.width + minInterItemSpacing) > containerWidth && !shouldDisplayAllRecipients && recipientCellsToSet.count >= 1 {
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
                // TODO: add a good description.
                // TODO: Check with Dirk dynamic localization.
                let andMoreButtonTitle = NSLocalizedString("& \(surplusCellsVM.count) more", comment: "and X more button title")
                let andMoreCellViewModel = EmailViewModel.RecipientCollectionViewCellViewModel(title: andMoreButtonTitle, rowType: rowType) {
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
