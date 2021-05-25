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

    // MARK: - IBOutlets

    //As the container views are in a UIStackView, the height must be given.
    @IBOutlet private weak var bccContainerHeight: NSLayoutConstraint!
    @IBOutlet private weak var ccContainerHeight: NSLayoutConstraint!
    @IBOutlet private weak var toContainerHeight: NSLayoutConstraint!
    @IBOutlet private weak var fromCollectionViewHeight: NSLayoutConstraint!

    //These containers are used to hide when there is no cc/bcc recipeints.
    @IBOutlet weak var ccContainer: UIView!
    @IBOutlet weak var bccContainer: UIView!

    //Labels
    @IBOutlet private weak var toLabel: UILabel!
    @IBOutlet private weak var ccLabel: UILabel!
    @IBOutlet private weak var bccLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!

    //CollectionViews
    @IBOutlet private weak var fromCollectionView: UICollectionView!
    @IBOutlet private weak var tosCollectionView: UICollectionView!
    @IBOutlet private weak var ccsCollectionView: UICollectionView!
    @IBOutlet private weak var bccsCollectionView: UICollectionView!
    
    @IBOutlet private weak var contactImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        contactImageView.applyContactImageCornerRadius()
        contactImageView.image = MessageHeaderCell.emptyContactImage
    }

    public func setup(row: EmailViewModel.HeaderRow,
                      shouldDisplayAll: [EmailViewModel.RecipientType: Bool],
                      delegate: MessageHeaderCellDelegate) {

        self.viewModel = row.viewModel

        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }

        //Collection view containers
        bccContainer.isHidden = row.bccsViewModels.isEmpty
        ccContainer.isHidden = row.ccsViewModels.isEmpty

        setupLabels(row)

        /// Get image
        vm.getProfilePicture { [weak self] image in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.contactImageView.image = image
        }

        vm.setup(shouldDisplayAll: shouldDisplayAll,
                 recipientsContainerWidth: tosCollectionView.bounds.size.width,
                 fromContainerWidth: fromCollectionView.bounds.size.width,
                 fromViewModel: row.fromViewModel,
                 toViewModels: row.tosViewModels,
                 ccViewModels: row.ccsViewModels,
                 bccViewModels: row.bccsViewModels,
                 delegate: delegate)
        reloadAllCollectionViews()
    }

    func reloadAllRecipients(of recipientType: EmailViewModel.RecipientType) {
        let cv = collectionView(of: recipientType)
        cv.collectionViewLayout.invalidateLayout()
        cv.reloadData()
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
        guard let viewModels = recipientsCVVM(collectionView: collectionView)?.collectionViewCellViewModels else {
            Log.shared.errorAndCrash("VMs not found")
            return cell
        }

        switch collectionView {
        case fromCollectionView:
            cell.setup(with: viewModels[indexPath.row])
            let margin: CGFloat =  2.0
            fromCollectionViewHeight.constant = fromCollectionView.contentSize.height + margin
        case tosCollectionView:
            cell.setup(with: viewModels[indexPath.row])
            toContainerHeight.constant = tosCollectionView.contentSize.height
        case ccsCollectionView:
            cell.setup(with: viewModels[indexPath.row])
            ccContainerHeight.constant = ccsCollectionView.contentSize.height

        case bccsCollectionView:
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

    private func setup(label: UILabel, text: String) {
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

    private func collectionView(of recipientType: EmailViewModel.RecipientType) -> UICollectionView {
        switch recipientType {
        case .to:
            return tosCollectionView
        case .cc:
            return ccsCollectionView
        case .bcc:
            return bccsCollectionView
        case .from:
            return fromCollectionView
        }
    }

    private func reloadAllCollectionViews() {
        [.from, .to, .cc, .bcc].forEach({ reloadAllRecipients(of: $0) })
    }

    private func setupLabels(_ row: EmailViewModel.HeaderRow) {
        //Labels
        if let date = row.date {
            setup(label: dateLabel, text: date)
            dateLabel.isHidden = false
        } else {
            dateLabel.text = nil
            dateLabel.isHidden = true
        }
        setup(label: toLabel, text: RecipientCellViewModel.FieldType.to.localizedTitle())
        setup(label: ccLabel, text: RecipientCellViewModel.FieldType.cc.localizedTitle())
        setup(label: bccLabel, text: RecipientCellViewModel.FieldType.bcc.localizedTitle())
    }
}