//
//  EmailDetailCollectionViewCell.swift
//  pEp
//
//  Created by Andreas Buff on 10.12.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import pEpIOSToolbox

/// Cell that offers (only) a container to display an (Email)View in.
class EmailDetailCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var containerView: UIView!
    private weak var containedView: UIView?

    /// This cell
    public func setContainedView(containedView: UIView) {
        self.containedView = containedView
        containerView.addSubview(containedView)
        containedView.fullSizeInSuperView()
    }

    override func prepareForReuse() {
        // Remove the previously shown EmailViewController view
        removeContatinedView()
        isSelected = false
    }
}

// MARK: - Private

extension EmailDetailCollectionViewCell {

    private func removeContatinedView() {
        containedView?.removeFromSuperview()
        containedView = nil
    }
}
