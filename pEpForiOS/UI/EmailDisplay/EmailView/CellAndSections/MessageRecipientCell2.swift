//
//  MessageRecipientCell2.swift
//  pEp
//
//  Created by Martín Brude on 21/4/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox

class MessageRecipientCell2: UITableViewCell {
    private var minHeight: CGFloat? = 20.0

    @IBOutlet private weak var collectionView: UICollectionView!

    private var recipientCollectionViewCellViewModels: [EmailViewModel.RecipientCollectionViewCellViewModel]?

    // 1
    public func setup(viewModels: [EmailViewModel.RecipientCollectionViewCellViewModel],
                      type: EmailViewModel.EmailRowType) {
        setRecipientCollectionViewCellViewModels(type, viewModels)
        setupCollectionView()
    }
}

// MARK: - Setup

extension MessageRecipientCell2 {
    // 2
    private func setRecipientCollectionViewCellViewModels(_ type: EmailViewModel.EmailRowType,
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

    // 3
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

    // 4
    private func set(_ text: String,
                     _ recipientsCellVMs: [EmailViewModel.RecipientCollectionViewCellViewModel],
                     rowType: EmailViewModel.EmailRowType) {
        var cellViewModels = [EmailViewModel.RecipientCollectionViewCellViewModel(title: text, rowType: rowType)]

        cellViewModels.append(recipientsCellVMs)
        //Check if buttons will exceed 1 line
        let containerWidth = collectionView.frame.size.width
        var currentOriginX: CGFloat = 0

        var surplusCellsVM = [EmailViewModel.RecipientCollectionViewCellViewModel]()
        var cellsVMToAppend = [EmailViewModel.RecipientCollectionViewCellViewModel]()

        for (index, cellvm) in cellViewModels.enumerated() {
            // Would the next cell exceed the container width?
            // If so, separate the surplus.
            if currentOriginX + cellvm.size.width > containerWidth {
                // would exceed the line
                let surplus = cellViewModels[index..<cellViewModels.count - 1]
                surplusCellsVM.append(contentsOf: surplus)
                break
            } else {
                currentOriginX += cellvm.size.width
                cellsVMToAppend.append(cellvm)
            }
        }
        cellViewModels.append(contentsOf: cellsVMToAppend)
        self.recipientCollectionViewCellViewModels = cellsVMToAppend
    }

    private func setupCollectionView() {
        collectionView.scrollsToTop = false
        let layout = LeftAlignedCollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2
        collectionView.collectionViewLayout = layout
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
    }
}

// MARK: - UICollectionViewDelegate

extension MessageRecipientCell2: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecipientCollectionViewCell.cellId,
                                                            for: indexPath) as? RecipientCollectionViewCell else {
            Log.shared.errorAndCrash("Error setting up cell")
            return collectionView.dequeueReusableCell(withReuseIdentifier: RecipientCollectionViewCell.cellId, for: indexPath)
        }
        guard let recipientCollectionViewCellViewModels = recipientCollectionViewCellViewModels else {
            Log.shared.errorAndCrash("VMs not found")
            return cell
        }
        let collectionViewCellViewModel = recipientCollectionViewCellViewModels[indexPath.row]
        cell.setup(with: collectionViewCellViewModel)
        return cell
    }
}

// MARK: - UICollectionViewDataSource

extension MessageRecipientCell2: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let recipientCollectionViewCellViewModels = recipientCollectionViewCellViewModels else {
            Log.shared.errorAndCrash("The cell can not have zero recipients")
            return 0
        }
        return recipientCollectionViewCellViewModels.count
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MessageRecipientCell2: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        guard let vm = recipientCollectionViewCellViewModels else {
            Log.shared.errorAndCrash("VMs not found")
            return .zero
        }

        return vm[indexPath.row].size
    }
}

// MARK: - UIConstraintBasedLayoutFittingSize

extension MessageRecipientCell2 {

    override func systemLayoutSizeFitting(_ targetSize: CGSize,
                                          withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
                                          verticalFittingPriority: UILayoutPriority) -> CGSize {
        let size = super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority,
                                                 verticalFittingPriority: verticalFittingPriority)
        guard let minHeight = minHeight else { return size }
        let expectedHeight = collectionView.collectionViewLayout.collectionViewContentSize.height
        return CGSize(width: size.width, height: max(expectedHeight, minHeight))
    }
}

