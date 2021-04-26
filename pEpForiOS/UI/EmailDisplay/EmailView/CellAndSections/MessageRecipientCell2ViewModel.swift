//
//  MessageRecipientCell2ViewModel.swift
//  pEp
//
//  Created by Martín Brude on 26/4/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox

class MessageRecipientCell2ViewModel {

    private var containerWidth: CGFloat = 0.0
    private var displayAll = false
    public weak var delegate : MessageRecipientCell2Delegate?
    public var recipientCollectionViewCellViewModels: [EmailViewModel.RecipientCollectionViewCellViewModel]?
    private var rowType : EmailViewModel.EmailRowType = .from2

    public func recipientCollectionViewCellViewModelToSet(_ text: String,
                     _ recipientsCellVMs: [EmailViewModel.RecipientCollectionViewCellViewModel],
                     rowType: EmailViewModel.EmailRowType,
                     containerWidth: CGFloat) -> [EmailViewModel.RecipientCollectionViewCellViewModel] {
        //'To' button, for example.
        let recipientTypeCellViewModel = EmailViewModel.RecipientCollectionViewCellViewModel(title: text, rowType: rowType)
        var cellsViewModelsToSet = [recipientTypeCellViewModel]

        //Check if buttons will exceed 1 line
        var currentOriginX: CGFloat = 0

        var surplusCellsVM = [EmailViewModel.RecipientCollectionViewCellViewModel]()
        var cellsVMToAppend = [EmailViewModel.RecipientCollectionViewCellViewModel]()

        //Recipients buttons
        for (index, cellvm) in recipientsCellVMs.enumerated() {
            // Would the next cell exceed the container width?
            // If so, separate the surplus.
            if currentOriginX + cellvm.size.width > containerWidth && !displayAll {
                // would exceed the line
                let surplus = recipientsCellVMs[index..<recipientsCellVMs.count]
                surplusCellsVM.append(contentsOf: surplus)
                break
            } else {
                currentOriginX += cellvm.size.width
                cellsVMToAppend.append(cellvm)
            }
        }
        cellsViewModelsToSet.append(contentsOf: cellsVMToAppend)

        if !surplusCellsVM.isEmpty {
            //'& X more' button.
            let andMoreButtonTitle = NSLocalizedString("& \(surplusCellsVM.count) more", comment: "and X more button title")
            let andMoreCellViewModel = EmailViewModel.RecipientCollectionViewCellViewModel(title: andMoreButtonTitle, rowType: rowType) { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }
                me.delegate?.displayAllRecipients()
            }
            cellsViewModelsToSet.append(andMoreCellViewModel)
        }

        return cellsViewModelsToSet
    }

    public func setRecipientCollectionViewCellViewModels(_ type: EmailViewModel.EmailRowType,
                                                         _ recipientCollectionViewCellViewModels: [EmailViewModel.RecipientCollectionViewCellViewModel]) {
        switch type {
        case .from2:
            self.recipientCollectionViewCellViewModels = recipientCollectionViewCellViewModels
        case .to2:
            setToRecipientCollectionViewCellViewModels(recipientCollectionViewCellViewModels)
        case .cc2:
            setCCRecipientCollectionViewCellViewModels(recipientCollectionViewCellViewModels)
        case .bcc2:
            setBCCRecipientCollectionViewCellViewModels(recipientCollectionViewCellViewModels)
        default:
            Log.shared.errorAndCrash("Email Row type not supported")
        }
    }

    private func setToRecipientCollectionViewCellViewModels(_ recipientsVMs: [EmailViewModel.RecipientCollectionViewCellViewModel]) {
        let to = RecipientCellViewModel.FieldType.to.localizedTitle()
        set(to, recipientsVMs, rowType: .to2)
    }

    private func setCCRecipientCollectionViewCellViewModels(_ recipientsVMs: [EmailViewModel.RecipientCollectionViewCellViewModel]) {
        let cc = RecipientCellViewModel.FieldType.cc.localizedTitle()
        set(cc, recipientsVMs, rowType: .cc2)
    }

    private func setBCCRecipientCollectionViewCellViewModels(_ recipientsVMs: [EmailViewModel.RecipientCollectionViewCellViewModel]) {
        let bcc = RecipientCellViewModel.FieldType.bcc.localizedTitle()
        set(bcc, recipientsVMs, rowType: .bcc2)
    }

    private func set(_ text: String,
                     _ recipientsCellVMs: [EmailViewModel.RecipientCollectionViewCellViewModel],
                     rowType: EmailViewModel.EmailRowType) {
        self.recipientCollectionViewCellViewModels = recipientCollectionViewCellViewModelToSet(text, recipientsCellVMs,
                                                                                               rowType: rowType,
                                                                                               containerWidth: containerWidth)
    }
}

extension MessageRecipientCell2ViewModel {
    
    public func setup(displayAll: Bool, containerWidth: CGFloat, type: EmailViewModel.EmailRowType, viewModels: [EmailViewModel.RecipientCollectionViewCellViewModel]) {
        self.displayAll = displayAll
        self.containerWidth = containerWidth
        self.rowType = type
        setRecipientCollectionViewCellViewModels(type, viewModels)
    }
}
