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

    private var recipientVMs: [EmailViewModel.RecipientCellViewModel]?

    @IBOutlet private weak var collectionView: UICollectionView!

    public func setup(recipientsVMs: [EmailViewModel.RecipientCellViewModel], type: EmailViewModel.EmailRowType) {
        setVMs(type, recipientsVMs)
        setupCollectionView()
    }
}

// MARK: - Setup

extension MessageRecipientCell2 {

    private func setToViewModels(_ recipientsVMs: [EmailViewModel.RecipientCellViewModel]) {
        let to = NSLocalizedString("To:", comment: "To: - To label")
        setVM(to, recipientsVMs)
    }

    private func setCCViewModels(_ recipientsVMs: [EmailViewModel.RecipientCellViewModel]) {
        let cc = NSLocalizedString("Cc:", comment: "Cc: - Cc label")
        setVM(cc, recipientsVMs)
    }

    private func setBCCViewModels(_ recipientsVMs: [EmailViewModel.RecipientCellViewModel]) {
        let bcc = NSLocalizedString("BCc:", comment: "BCc: - BCc label")
        setVM(bcc, recipientsVMs)
    }

    private func setVM(_ text: String, _ recipientsVMs: [EmailViewModel.RecipientCellViewModel]) {
        let baseVM = EmailViewModel.RecipientCellViewModel(title: text)
        var cellViewModels = [baseVM]
        cellViewModels.append(contentsOf: recipientsVMs)
        self.recipientVMs = cellViewModels
    }

    private func setVMs(_ type: EmailViewModel.EmailRowType, _ recipientsVMs: [EmailViewModel.RecipientCellViewModel]) {
        switch type {
        case .from2:
            self.recipientVMs = recipientsVMs
        case .sender2:
            setToViewModels(recipientsVMs)
        case .cc2:
            setCCViewModels(recipientsVMs)
        case .bcc2:
            setBCCViewModels(recipientsVMs)
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

        guard let vm = recipientVMs else {
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
        guard let vms = recipientVMs else {
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

        guard let vm = recipientVMs else {
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
