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

    private var recipientCollectionViewCellViewModels: [EmailViewModel.RecipientCollectionViewCellViewModel]?

    @IBOutlet private weak var collectionView: UICollectionView!

    public func setup(recipientsCellVMs: [EmailViewModel.RecipientCollectionViewCellViewModel], type: EmailViewModel.EmailRowType) {
        setVMs(type, recipientsCellVMs)
        setupCollectionView()
    }
}

// MARK: - Setup

extension MessageRecipientCell2 {

    private func setToRecipientCollectionViewCellViewModels(_ recipientsVMs: [EmailViewModel.RecipientCollectionViewCellViewModel]) {
        let to = NSLocalizedString("To:", comment: "To: - To label")
        set(to, recipientsVMs)
    }

    private func setCCRecipientCollectionViewCellViewModels(_ recipientsVMs: [EmailViewModel.RecipientCollectionViewCellViewModel]) {
        let cc = NSLocalizedString("Cc:", comment: "Cc: - Cc label")
        set(cc, recipientsVMs)
    }

    private func setBCCRecipientCollectionViewCellViewModels(_ recipientsVMs: [EmailViewModel.RecipientCollectionViewCellViewModel]) {
        let bcc = NSLocalizedString("BCc:", comment: "BCc: - BCc label")
        set(bcc, recipientsVMs)
    }

    private func set(_ text: String, _ recipientsCellVMs: [EmailViewModel.RecipientCollectionViewCellViewModel]) {
        var cellViewModels = [EmailViewModel.RecipientCollectionViewCellViewModel(title: text)]
        cellViewModels.append(contentsOf: recipientsCellVMs)
        self.recipientCollectionViewCellViewModels = cellViewModels
    }

    private func setVMs(_ type: EmailViewModel.EmailRowType, _ recipientCollectionViewCellViewModels: [EmailViewModel.RecipientCollectionViewCellViewModel]) {
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

    private func setupCollectionView() {
        collectionView.scrollsToTop = false
        let layout = LeftAlignedCollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 4
        collectionView.collectionViewLayout = layout
        collectionView.reloadData()
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

        guard let vm = recipientCollectionViewCellViewModels else {
            Log.shared.errorAndCrash("VMs not found")
            return cell
        }

        cell.setup(cellVM: vm[indexPath.row])
        return cell
    }
}

// MARK: - UICollectionViewDataSource

extension MessageRecipientCell2: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let vms = recipientCollectionViewCellViewModels else {
            Log.shared.errorAndCrash("The cell can not have zero recipients")
            return 0
        }
        return vms.count
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

        let title = vm[indexPath.row].title
        let action = vm[indexPath.row].action
        let recipientButton = RecipientButton(type: .system)
        recipientButton.setup(text: title, action: action)

        return recipientButton.frame.size
    }
}

