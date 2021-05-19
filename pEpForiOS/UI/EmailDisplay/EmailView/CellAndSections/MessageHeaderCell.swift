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

class MessageHeaderCell: UITableViewCell {

    private static let emptyContactImage = UIImage(named: "empty-avatar")

    private var viewModel: MessageHeaderCellViewModel?
    private var minHeight: CGFloat? = 80.0

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
        bccContainer.isHidden = bccViewModels.isEmpty
        ccContainer.isHidden = ccViewModels.isEmpty

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

        self.viewModel = viewModel
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

        [fromCollectionView, tosCollectionView, ccsCollectionView, bccsCollectionView].forEach { cv in
            guard let alignedFlowLayout = cv?.collectionViewLayout as? AlignedCollectionViewFlowLayout else {
                Log.shared.errorAndCrash("AlignedCollectionViewFlowLayout not found")
                return
            }

            alignedFlowLayout.horizontalAlignment = .left
            alignedFlowLayout.verticalAlignment = .top
            alignedFlowLayout.minimumInteritemSpacing = 2
            alignedFlowLayout.minimumLineSpacing = 2
        }
    }
}

// MARK: - Collection View

extension MessageHeaderCell {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
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

        switch collectionView {
        case fromCollectionView:
            guard let viewModels = viewModel?.fromCollectionViewViewModel?.collectionViewCellViewModels else {
                Log.shared.errorAndCrash("VMs not found")
                return cell
            }
            let collectionViewCellViewModel = viewModels[indexPath.row]
            cell.setup(with: collectionViewCellViewModel)
            return cell
        case tosCollectionView:
            guard let viewModels = viewModel?.tosCollectionViewViewModel?.collectionViewCellViewModels else {
                Log.shared.errorAndCrash("VMs not found")
                return cell
            }
            let collectionViewCellViewModel = viewModels[indexPath.row]
            cell.setup(with: collectionViewCellViewModel)
            return cell

        case ccsCollectionView:
            guard let viewModels = viewModel?.ccsCollectionViewViewModel?.collectionViewCellViewModels else {
                Log.shared.errorAndCrash("VMs not found")
                return cell
            }
            let collectionViewCellViewModel = viewModels[indexPath.row]
            cell.setup(with: collectionViewCellViewModel)
            return cell

        case bccsCollectionView:
            guard let viewModels = viewModel?.ccsCollectionViewViewModel?.collectionViewCellViewModels else {
                Log.shared.errorAndCrash("VMs not found")
                return cell
            }
            let collectionViewCellViewModel = viewModels[indexPath.row]
            cell.setup(with: collectionViewCellViewModel)
            return cell

        default:
            Log.shared.errorAndCrash("CV not found")

        }

        guard let viewModels = viewModel?.tosCollectionViewViewModel?.collectionViewCellViewModels else {
            Log.shared.errorAndCrash("VMs not found")
            return cell
        }
        let collectionViewCellViewModel = viewModels[indexPath.row]
        cell.setup(with: collectionViewCellViewModel)
        return cell
    }
}

// MARK: - UICollectionViewDataSource

extension MessageHeaderCell: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        switch collectionView {
        case fromCollectionView:
            guard let viewModels = viewModel?.fromCollectionViewViewModel?.collectionViewCellViewModels else {
                return 0
            }
            return viewModels.count

        case tosCollectionView:
            guard let viewModels = viewModel?.tosCollectionViewViewModel?.collectionViewCellViewModels else {
                return 0
            }
            return viewModels.count

        case ccsCollectionView:
            guard let viewModels = viewModel?.ccsCollectionViewViewModel?.collectionViewCellViewModels else {
                return 0
            }
            return viewModels.count

        case bccsCollectionView:
            guard let viewModels = viewModel?.bccsCollectionViewViewModel?.collectionViewCellViewModels else {
                return 0
            }
            return viewModels.count


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

        guard let vm = recipientsCVVM(collectionView: collectionView)?.collectionViewCellViewModels else {
            Log.shared.errorAndCrash("VMs not found")
            return .zero
        }
        let size = vm[indexPath.row].size
        let margin = CGFloat(8.0)
        // The item max width is the the collection view width minus the margin.
        let maxSize = CGSize(width: collectionView.bounds.width - margin, height: size.height)
        if maxSize.width < size.width {
            return maxSize
        }
        return size
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
            Log.shared.errorAndCrash("Oops")
        }
        return nil
    }
}

//// MARK: - UIConstraintBasedLayoutFittingSize
//
//extension MessageHeaderCell {

//    override func systemLayoutSizeFitting(_ targetSize: CGSize,
//                                          withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
//                                          verticalFittingPriority: UILayoutPriority) -> CGSize {
//        let size = super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
//        var bccExpectedHeight: CGFloat = 0.0
//        var ccExpectedHeight: CGFloat = 0.0
//        let fromExpectedHeight = fromCollectionView.collectionViewLayout.collectionViewContentSize.height
//        let toExpectedHeight = tosCollectionView.collectionViewLayout.collectionViewContentSize.height
//        if hasBCCRecipients {
//            bccExpectedHeight = bccsCollectionView.collectionViewLayout.collectionViewContentSize.height
//        }
//        if hasCCRecipients {
//            ccExpectedHeight = ccsCollectionView.collectionViewLayout.collectionViewContentSize.height
//        }
//        let dateLabelExpectedHeight = dateLabel.bounds.size.height
//        let expectatedTotalHeight = fromExpectedHeight + toExpectedHeight + ccExpectedHeight + bccExpectedHeight + dateLabelExpectedHeight + 30
//        return CGSize(width: size.width, height: expectatedTotalHeight)
//    }
//
//    private var hasBCCRecipients: Bool {
//        guard let cvcvms = viewModel?.bccsCollectionViewViewModel?.collectionViewCellViewModels else {
//            return false
//        }
//        return cvcvms.count > 0
//    }
//
//    private var hasCCRecipients: Bool {
//        guard let cvcvms = viewModel?.ccsCollectionViewViewModel?.collectionViewCellViewModels else {
//            return false
//        }
//
//        return cvcvms.count > 0
//    }
//}

extension MessageHeaderCell {
    
    public func clear() {
        viewModel?.unsubscribeForUpdates()
        viewModel = nil
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
}
