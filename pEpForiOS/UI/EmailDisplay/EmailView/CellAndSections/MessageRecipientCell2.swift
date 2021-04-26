//
//  MessageRecipientCell2.swift
//  pEp
//
//  Created by Martín Brude on 21/4/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox
protocol MessageRecipientCell2Delegate: class {
    func displayAllRecipients(rowType: EmailViewModel.EmailRowType)
}

class MessageRecipientCell2: UITableViewCell {
    private var minHeight: CGFloat? = 20.0
    @IBOutlet private weak var collectionView: UICollectionView!

    public let viewModel = MessageRecipientCell2ViewModel()

    public func setup(viewModels: [EmailViewModel.RecipientCollectionViewCellViewModel],
                      type: EmailViewModel.EmailRowType,
                      shouldDisplayAll: Bool) {
        setupViewModel(shouldDisplayAll, type, viewModels)
        setupCollectionView()
    }
}

// MARK: - ViewModel

extension MessageRecipientCell2 {

    private func setupViewModel(_ shouldDisplayAll: Bool,
                                _ rowType: EmailViewModel.EmailRowType,
                                _ recipientCollectionViewCellViewModels: [EmailViewModel.RecipientCollectionViewCellViewModel]) {
        viewModel.setup(shouldDisplayAll: shouldDisplayAll,
                        containerWidth: collectionView.frame.size.width,
                        rowType: rowType,
                        recipientCollectionViewCellViewModels: recipientCollectionViewCellViewModels)
    }
}

// MARK: - Collection View

extension MessageRecipientCell2 {

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
        guard let recipientCollectionViewCellViewModels = viewModel.recipientCollectionViewCellViewModels else {
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
        guard let recipientCollectionViewCellViewModels = viewModel.recipientCollectionViewCellViewModels else {
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

        guard let vm = viewModel.recipientCollectionViewCellViewModels else {
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
