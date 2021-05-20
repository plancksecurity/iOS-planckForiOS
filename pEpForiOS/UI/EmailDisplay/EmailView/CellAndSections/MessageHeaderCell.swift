//
//  MessageHeaderCell.swift
//  pEp
//
//  Created by Martín Brude on 17/5/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit
import Foundation

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

protocol MessageHeaderCellDelegate: AnyObject {
    func displayAllRecipients(recipientType: EmailViewModel.RecipientType)
}

class MessageHeaderCell: UITableViewCell {

    private static let emptyContactImage = UIImage(named: "empty-avatar")

    private var viewModel: MessageHeaderCellViewModel?
    private var minHeight: CGFloat? = 80.0

    @IBOutlet private weak var bccContainerHeight: NSLayoutConstraint!
    @IBOutlet private weak var ccContainerHeight: NSLayoutConstraint!
    @IBOutlet private weak var toContainerHeight: NSLayoutConstraint!
    @IBOutlet private weak var fromCollectionViewHeight: NSLayoutConstraint!

    @IBOutlet weak var ccContainer: UIView!
    @IBOutlet weak var bccContainer: UIView!

    @IBOutlet private weak var toLabel: UILabel!
    @IBOutlet private weak var ccLabel: UILabel!
    @IBOutlet private weak var bccLabel: UILabel!

    @IBOutlet private weak var fromCollectionView: UICollectionView!
    @IBOutlet private weak var tosCollectionView: UICollectionView!
    @IBOutlet private weak var ccsCollectionView: UICollectionView!
    @IBOutlet private weak var bccsCollectionView: UICollectionView!
    
    @IBOutlet weak var contactImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        contactImageView.applyContactImageCornerRadius()
        contactImageView.image = MessageHeaderCell.emptyContactImage
    }

    public func setup(fromViewModel: EmailViewModel.CollectionViewCellViewModel,
                      toViewModels: [EmailViewModel.CollectionViewCellViewModel],
                      ccViewModels: [EmailViewModel.CollectionViewCellViewModel],
                      bccViewModels: [EmailViewModel.CollectionViewCellViewModel],
                      date: String?,
                      viewModel: MessageHeaderCellViewModel,
                      rowType: EmailViewModel.EmailRowType,
                      shouldDisplayAll: [EmailViewModel.RecipientType: Bool],
                      delegate: MessageHeaderCellDelegate,
                      viewWidth: CGFloat) {

        self.viewModel = viewModel

        //Collection view containers
        bccContainer.isHidden = bccViewModels.isEmpty
        ccContainer.isHidden = ccViewModels.isEmpty

        //Labels
        if let date = date {
            setupRecipientLabel(label: dateLabel, text: date)
            dateLabel.isHidden = false
        } else {
            dateLabel.text = nil
            dateLabel.isHidden = true
        }
        setupRecipientLabel(label: toLabel, text: RecipientCellViewModel.FieldType.to.localizedTitle())
        setupRecipientLabel(label: ccLabel, text: RecipientCellViewModel.FieldType.cc.localizedTitle())
        setupRecipientLabel(label: bccLabel, text: RecipientCellViewModel.FieldType.bcc.localizedTitle())

        /// Get image
        viewModel.getProfilePicture { [weak self] image in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.contactImageView.image = image
        }

        let margin: CGFloat = 90.0
        viewModel.setup(shouldDisplayAll: shouldDisplayAll,
                        containerWidth: ccContainer.bounds.size.width - margin,
                        rowType: rowType,
                        fromViewModel: fromViewModel,
                        toViewModels: toViewModels,
                        ccViewModels: ccViewModels,
                        bccViewModels: bccViewModels,
                        delegate: delegate)
    }
}

// MARK: - UICollectionViewDelegate

extension MessageHeaderCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecipientCollectionViewCell.cellId,
                                                            for: indexPath) as? RecipientCollectionViewCell else {
            Log.shared.errorAndCrash("Error setting up cell")
            return collectionView.dequeueReusableCell(withReuseIdentifier: RecipientCollectionViewCell.cellId, for: indexPath)
        }

        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return collectionView.dequeueReusableCell(withReuseIdentifier: RecipientCollectionViewCell.cellId, for: indexPath)
        }

        switch collectionView {
        case fromCollectionView:
            guard let viewModels = vm.fromCollectionViewViewModel?.collectionViewCellViewModels else {
                Log.shared.errorAndCrash("VMs not found")
                return cell
            }
            cell.setup(with: viewModels[indexPath.row])
            fromCollectionViewHeight.constant = fromCollectionView.contentSize.height
        case tosCollectionView:
            guard let viewModels = vm.tosCollectionViewViewModel?.collectionViewCellViewModels else {
                Log.shared.errorAndCrash("VMs not found")
                return cell
            }
            cell.setup(with: viewModels[indexPath.row])
            toContainerHeight.constant = tosCollectionView.contentSize.height

        case ccsCollectionView:
            guard let viewModels = vm.ccsCollectionViewViewModel?.collectionViewCellViewModels else {
                Log.shared.errorAndCrash("VMs not found")
                return cell
            }
            cell.setup(with: viewModels[indexPath.row])
            ccContainerHeight.constant = ccsCollectionView.contentSize.height

        case bccsCollectionView:
            guard let viewModels = vm.bccsCollectionViewViewModel?.collectionViewCellViewModels else {
                Log.shared.errorAndCrash("VMs not found")
                return cell
            }
            cell.setup(with: viewModels[indexPath.row])
            bccContainerHeight.constant = bccsCollectionView.contentSize.height
        default:
            Log.shared.errorAndCrash("CV not found")
        }
        return cell
    }
}

// MARK: - UICollectionViewDataSource

extension MessageHeaderCell: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case fromCollectionView:
            return viewModel?.fromCollectionViewViewModel?.numberOfCollectionViewCellViewModels ?? 0
        case tosCollectionView:
            return viewModel?.tosCollectionViewViewModel?.numberOfCollectionViewCellViewModels ?? 0
        case ccsCollectionView:
            return viewModel?.ccsCollectionViewViewModel?.numberOfCollectionViewCellViewModels ?? 0
        case bccsCollectionView:
            return viewModel?.bccsCollectionViewViewModel?.numberOfCollectionViewCellViewModels ?? 0
        default:
            Log.shared.errorAndCrash("CV not found")
            return 0
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MessageHeaderCell: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        guard let vms = recipientsCVVM(collectionView: collectionView)?.collectionViewCellViewModels else {
            Log.shared.errorAndCrash("VMs not found")
            return .zero
        }
        let size = vms[indexPath.row].size
        let margin = CGFloat(8.0)
        // The item max width is the the collection view width minus the margin.
        let maxSize = CGSize(width: collectionView.bounds.width - margin, height: size.height)
        if maxSize.width < size.width {
            return maxSize
        }
        return size
    }
}

//MARK: - Private

extension MessageHeaderCell {

    private func setupRecipientLabel(label: UILabel, text: String) {
        label.text = text
        label.font = UIFont.pepFont(style: .footnote, weight: .semibold)
        if #available(iOS 13.0, *) {
            label.textColor = .secondaryLabel
        } else {
            label.textColor = .lightGray
        }
    }

    private func recipientsCVVM(collectionView: UICollectionView) -> EmailViewModel.RecipientsCollectionViewViewModel? {
        switch collectionView {
        case fromCollectionView:
            return viewModel?.fromCollectionViewViewModel
        case tosCollectionView:
            return viewModel?.tosCollectionViewViewModel
        case ccsCollectionView:
            return viewModel?.ccsCollectionViewViewModel
        case bccsCollectionView:
            return viewModel?.bccsCollectionViewViewModel

        default:
            Log.shared.errorAndCrash("unknown collectionview")
        }
        return nil
    }
}
